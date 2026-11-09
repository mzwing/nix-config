{
  config,
  hostname,
  lib,
  pkgs,
  ...
}: let
  hm = config.home-manager.users.root;
  syncthing = import ../../../../data/syncthing.nix;

  # Where Remote-SSH's server keeps each profile's extension list; without relativeLocation it loads them from the store instead of its own extensions dir.
  vscodeServer = pkgs.linkFarm "vscode-server" (lib.mapAttrsToList (name: profile: {
      name =
        if name == "default"
        then "extensions/extensions.json"
        else "data/User/profiles/${name}/extensions.json";
      path = pkgs.writeText "${name}-extensions.json" (builtins.toJSON (map (ext: removeAttrs (pkgs.vscode-utils.toExtensionJsonEntry ext) ["relativeLocation"]) profile.extensions));
    })
    hm.programs.vscodium.profiles);
in {
  networking.hostName = hostname;

  # Its NARs crawl over CNB's link to Hetzner, about 5 KB/s, so the unfree Android SDK pieces only it holds build from Google's downloads instead
  mzwing.nix.unreachableSubstituters = ["https://cache.nixos-cuda.org"];

  services.openssh = {
    enable = true;
    # CNB runs sshd with UsePAM=no and logs in by password; without libxcrypt sshd falls back to OpenSSL's DES-only crypt and rejects every yescrypt hash.
    package = pkgs.openssh.overrideAttrs (old: {
      buildInputs = old.buildInputs ++ [pkgs.libxcrypt];
    });
  };

  # Every workspace starts with an empty ~/.paseo, where the daemon would mint a new server ID that the apps take for another host
  services.paseo.environment.PASEO_SERVER_ID = hostname;

  users.users.root.createHome = true;

  # Remote-SSH downloads a VS Code server built for ordinary distros, matched to whatever version the client runs.
  programs.nix-ld.enable = true;

  # NixOS places the loader with tmpfiles, which can't run on CNB's 5.4 kernel: systemd 262 resolves paths through statx's mount id, new in 5.8
  system.activationScripts.ldso = ''
    mkdir -p /lib64
    ln -sfn ${config.environment.ldso} /lib64/ld-linux-x86-64.so.2
  '';

  # CNB expects the Debian layout its docs install into, e.g. sshd at /usr/sbin/sshd.
  system.activationScripts.debianPaths = lib.stringAfter ["binsh"] ''
    ln -sfn ${pkgs.bashInteractive}/bin/bash /bin/bash
    mkdir -p /usr/sbin
    ln -sfn ${config.services.openssh.package}/bin/sshd /usr/sbin/sshd
  '';

  home-manager.users.root = {lib, ...}: {
    # CNB skips roaming a ~/.gitconfig that already exists, and its tools write to it with `git config --global`.
    home.activation.gitconfig = lib.hm.dag.entryAfter ["linkGeneration"] ''
      run touch ~/.gitconfig
    '';
  };

  # Run by the vscode pipeline in .cnb.yml, once CNB has injected AGENIX_KEY and mounted its own /root/.vscode-server over the image's.
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "vscode-server-extensions" ''
      cp -rLT --no-preserve=mode ${vscodeServer} /root/.vscode-server
    '')
    (pkgs.writeShellScriptBin "agenix-unlock" ''
      install -D -m 600 /dev/stdin /root/.ssh/agenix <<<"$AGENIX_KEY"
      exec systemctl3 --user start agenix
    '')
    (pkgs.writeShellApplication {
      name = "repos-sync-wait";
      runtimeInputs = with pkgs; [curl jq xmlstarlet];
      text = ''
        case "''${1:-}" in
          pull|push) ;;
          *)
            echo "usage: repos-sync-wait pull|push" >&2
            exit 2
            ;;
        esac

        hub_id=${lib.escapeShellArg syncthing.devices.${syncthing.hub}.id}
        api_key=$(xmlstarlet sel -t -v /configuration/gui/apikey /root/.local/state/syncthing/config.xml)
        api=http://${hm.services.syncthing.guiAddress}/rest

        if [ "$1" = push ]; then
          echo "repos-sync-wait: scanning repos"
          curl -fsS -X POST -H "X-API-Key: $api_key" "$api/db/scan?folder=repos"
        fi

        while :; do
          connections=$(curl -fsS -H "X-API-Key: $api_key" "$api/system/connections")
          status=$(curl -fsS -H "X-API-Key: $api_key" "$api/db/status?folder=repos")
          connected=$(jq -r --arg hub_id "$hub_id" '.connections[$hub_id].connected' <<<"$connections")
          if [ "$1" = pull ]; then
            echo "repos-sync-wait: hub connected=$connected, $(jq -c '{state, needTotalItems, globalTotalItems}' <<<"$status")"
            if [ "$connected" = true ] && jq -e '.state == "idle" and .needTotalItems == 0 and .globalTotalItems > 0' <<<"$status" >/dev/null; then
              break
            fi
          else
            completion=$(curl -fsS -H "X-API-Key: $api_key" "$api/db/completion?folder=repos&device=$hub_id")
            echo "repos-sync-wait: hub connected=$connected, $(jq -c '{state}' <<<"$status"), $(jq -c '{completion, needItems, remoteState}' <<<"$completion")"
            if [ "$connected" = true ] && jq -e '.state == "idle"' <<<"$status" >/dev/null && jq -e '.completion == 100 and .needItems == 0 and .remoteState == "valid"' <<<"$completion" >/dev/null; then
              break
            fi
          fi
          sleep 30
        done
      '';
    })
  ];
}
