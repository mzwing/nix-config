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

  services.openssh = {
    enable = true;
    # CNB runs sshd with UsePAM=no and logs in by password; without libxcrypt sshd falls back to OpenSSL's DES-only crypt and rejects every yescrypt hash.
    package = pkgs.openssh.overrideAttrs (old: {
      buildInputs = old.buildInputs ++ [pkgs.libxcrypt];
    });
  };

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
    programs.git = {
      settings.user.name = lib.mkForce "mzwing";
      signing.signByDefault = lib.mkForce false;
    };

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
      runtimeInputs = with pkgs; [age crane fd git gnutar zstd];
      text = ''
        ref="$CNB_DOCKER_REGISTRY/$CNB_REPO_SLUG_LOWERCASE/workspace-snapshot"
        # Only a workspace that restored the snapshot may replace it, or a failed restore would save an empty tree over it
        restored=/run/workspace-snapshot-restored
        crane auth login "$CNB_DOCKER_REGISTRY" -u cnb --password-stdin <"${hm.age.secrets.registry-token.path}"

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
            # Ignored build outputs and devenv state come back on their own
            fd -HI -t d --prune --base-directory /root '^(target|build|\.gradle|\.cxx|\.devenv|\.direnv|node_modules|\.kotlin)$' repos | while read -r path; do
              if git -C "/root/$(dirname "$path")" check-ignore -q "$(basename "$path")" 2>/dev/null; then
                echo "$path"
              fi
            done >"$dir/excludes"
            tar -C /root -X "$dir/excludes" -cf - repos | zstd -T0 | age ${snapshotRecipients} >"$dir/snapshot"
            tar -C "$dir" -cf "$dir/layer.tar" snapshot
            old_latest=$(crane digest "$ref:latest")
            old_previous=$(crane digest "$ref:previous")
            crane append -f "$dir/layer.tar" -t "$ref:latest"
            # The one just replaced stays as a fallback
            crane tag "$ref@$old_latest" previous
            # Untagged, the registry would keep it as another full copy
            crane delete "$ref@$old_previous"
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
