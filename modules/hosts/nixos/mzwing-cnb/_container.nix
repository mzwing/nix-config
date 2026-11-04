{
  config,
  hostname,
  lib,
  pkgs,
  secrets,
  ...
}: let
  hm = config.home-manager.users.root;
  identities = import ../../../../data/identities.nix;

  # The workspace opens a snapshot with its own key, the Mac with the agenix one
  snapshotRecipients = lib.concatMapStringsSep " " (key: "-r ${lib.escapeShellArg key}") [
    identities.hosts.mzwing-cnb
    identities.age.mzwing
  ];

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

    age.secrets.registry-token.file = secrets."cnb/registry-token";
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
    # Carries /root/repos from one workspace to the next through the registry, encrypted since nix-config's is public
    (pkgs.writeShellApplication {
      name = "workspace-snapshot";
      runtimeInputs = with pkgs; [age crane curl fd git gnutar zstd];
      text = ''
        ref="$CNB_DOCKER_REGISTRY/$CNB_REPO_SLUG_LOWERCASE/workspace-snapshot"
        # Only a workspace that restored the snapshot may replace it, or a failed restore would save an empty tree over it
        restored=/run/workspace-snapshot-restored
        crane auth login "$CNB_DOCKER_REGISTRY" -u "$CNB_TOKEN_USER_NAME" --password-stdin <<<"$CNB_TOKEN"

        case "''${1:-}" in
          restore)
            crane export "$ref:latest" - | tar -xOf - snapshot | age -d -i /root/.ssh/agenix | zstd -d | tar -x -C /root
            touch "$restored"
            ;;
          save)
            if [ ! -e "$restored" ]; then
              echo "workspace-snapshot: this workspace restored nothing, so the snapshot stays as it is" >&2
              exit 1
            fi
            dir=$(mktemp -d)
            # Git-ignored devenv state and anything over 1 MiB, the size of caches and build outputs, stay out to come back from the network; small ignored files like keystores travel along
            fd -HI --prune --base-directory /root '^\.git$' repos | while read -r gitdir; do
              repo=$(dirname "$gitdir")
              git -C "/root/$repo" ls-files -z --others --ignored --exclude-standard --directory | while IFS= read -r -d "" path; do
                if [[ ''${path%/} =~ (^|/)\.(devenv|direnv)$ ]] || [ "$(du -sk "/root/$repo/$path" | cut -f1)" -gt 1024 ]; then
                  echo "$repo/''${path%/}"
                fi
              done
            done >"$dir/excludes"
            tar -C /root --anchored --no-wildcards -X "$dir/excludes" -cf - repos | zstd -T0 | age ${snapshotRecipients} >"$dir/snapshot"
            tar -C "$dir" -cf "$dir/layer.tar" snapshot
            old_latest=$(crane digest "$ref:latest")
            crane append -f "$dir/layer.tar" -t "$ref:latest"
            # The registry refuses deletes by digest; deleting a snapshot's only tag through the API deletes it
            curl -fsS -X DELETE -H "Authorization: Bearer $(<"${hm.age.secrets.registry-token.path}")" -H 'Accept: application/vnd.cnb.api+json' "$CNB_API_ENDPOINT/$CNB_REPO_SLUG/-/packages/docker/''${CNB_REPO_SLUG_LOWERCASE##*/}%2Fworkspace-snapshot/-/tag/previous"
            # The one just replaced stays as a fallback
            crane tag "$ref@$old_latest" previous
            rm -r "$dir"
            ;;
          *)
            echo "usage: workspace-snapshot restore|save" >&2
            exit 2
            ;;
        esac
      '';
    })
  ];
}
