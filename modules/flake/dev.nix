{inputs, ...}: {
  systems = [
    "aarch64-darwin"
    "x86_64-linux"
    "aarch64-linux"
  ];

  perSystem = {
    pkgs,
    system,
    ...
  }: {
    apps.nixos-anywhere = {
      type = "app";
      # Upstream appends the host's substituters to the installer's, keeping its default cache.nixos.org in front.
      program = "${inputs.nixos-anywhere.packages.${system}.default.overrideAttrs {
        postPatch = ''
          substituteInPlace src/nixos-anywhere.sh --replace-fail 'echo "extra-substituters = ' 'echo "substituters = '
        '';
      }}/bin/nixos-anywhere";
      meta.description = "Install NixOS hosts with nixos-anywhere.";
    };

    # Paths resolve from the working directory; run it from the repo root.
    apps.skills-sources-lock = {
      type = "app";
      program = "${inputs.agent-skills.lib.agent-skills.mkSourceLockProgram {
        inherit pkgs;
        manifestsDir = "data/skills/sources";
        lockFile = "data/skills/sources.lock.json";
      }}/bin/skills-sources-lock";
      meta.description = "Re-resolve data/skills/sources/*.nix into data/skills/sources.lock.json.";
    };

    formatter = pkgs.writeShellApplication {
      name = "nix-config-format";
      runtimeInputs = [pkgs.alejandra];
      text = ''
        if [ "$#" -eq 0 ]; then
          set -- .
        fi

        exec alejandra --exclude ./.devenv --exclude ./.devbox "$@"
      '';
    };
  };
}
