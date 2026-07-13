{
  config,
  inputs,
  lib,
  ...
}: let
  ciDarwinConfigurations =
    lib.mapAttrs (_: host: config.mzwing.lib.mkDarwinCIHost host) config.mzwing.hosts.darwin;
  ciNixosConfigurations =
    lib.mapAttrs (_: host: config.mzwing.lib.mkNixosCIHost host) config.mzwing.hosts.nixos;

  ciDarwinMatrix =
    lib.mapAttrs (name: host: {
      inherit (host) system;
      installable = ".#ciConfigurations.darwin.${name}.system";
      outputPath = ciDarwinConfigurations.${name}.system.outPath;
    })
    config.mzwing.hosts.darwin;

  ciNixosMatrix =
    lib.mapAttrs (name: host: {
      inherit (host) system;
      installable = ".#ciConfigurations.nixos.${name}.config.system.build.toplevel";
      outputPath = ciNixosConfigurations.${name}.config.system.build.toplevel.outPath;
    })
    config.mzwing.hosts.nixos;
in {
  systems = [
    "aarch64-darwin"
    "x86_64-linux"
    "aarch64-linux"
  ];

  flake = {
    darwinConfigurations = lib.mapAttrs (_: host: config.mzwing.lib.mkDarwinHost host) config.mzwing.hosts.darwin;
    nixosConfigurations = lib.mapAttrs (_: host: config.mzwing.lib.mkNixosHost host) config.mzwing.hosts.nixos;

    ciConfigurations = {
      darwin = ciDarwinConfigurations;
      nixos = ciNixosConfigurations;
    };

    debug.ci.matrix = {
      darwin = ciDarwinMatrix;
      nixos = ciNixosMatrix;
    };

    darwinModules = config.mzwing.lib.moduleAttrsFor "darwin";
    nixosModules = config.mzwing.lib.moduleAttrsFor "nixos";
    homeModules = config.mzwing.lib.moduleAttrsFor "home";
  };

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
