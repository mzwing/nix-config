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
      program = "${inputs.nixos-anywhere.packages.${system}.default}/bin/nixos-anywhere";
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
