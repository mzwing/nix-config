{
  config,
  inputs,
  lib,
  ...
}: {
  systems = [
    "aarch64-darwin"
    "x86_64-linux"
    "aarch64-linux"
  ];

  flake = {
    darwinConfigurations = lib.mapAttrs (_: host: config.mzwing.lib.mkDarwinHost host) config.mzwing.hosts.darwin;
    nixosConfigurations = lib.mapAttrs (_: host: config.mzwing.lib.mkNixosHost host) config.mzwing.hosts.nixos;

    darwinModules = config.mzwing.lib.moduleAttrsFor "darwin";
    nixosModules = config.mzwing.lib.moduleAttrsFor "nixos";
    homeModules = config.mzwing.lib.moduleAttrsFor "home";
  };

  perSystem = {
    pkgs,
    system,
    ...
  }: {
    formatter = pkgs.writeShellApplication {
      name = "nix-config-format";
      runtimeInputs = [pkgs.alejandra];
      text = ''
        if [ "$#" -eq 0 ]; then
          set -- .
        fi

        exec alejandra --exclude .devbox "$@"
      '';
    };
  };
}
