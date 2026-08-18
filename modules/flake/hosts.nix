# Assembling a host into a nix-darwin / NixOS system. One builder for both: everything that differs lives in `platforms` below.
{
  config,
  inputs,
  lib,
  ...
}: let
  inherit (config.mzwing.lib) selectFeatures selectCIFeatures modulesFor;

  # Secret paths by name, so no module has to spell out a path into secrets/.
  secretPaths = builtins.mapAttrs (_: entry: entry.file) (import ../../secrets/registry.nix);

  specialArgsFor = host: {
    inherit inputs;
    secrets = secretPaths;
    inherit
      (host)
      hostname
      system
      type
      username
      useremail
      ;
  };

  platforms = {
    darwin = {
      build = inputs.darwin.lib.darwinSystem;
      homeManagerModule = inputs.home-manager.darwinModules.home-manager;
      baseModules = [];
    };

    nixos = {
      build = inputs.nixpkgs.lib.nixosSystem;
      homeManagerModule = inputs.home-manager.nixosModules.home-manager;
      baseModules = [
        inputs.agenix.nixosModules.default
        inputs.disko.nixosModules.disko
      ];
    };
  };

  homeManagerConfig = host: homeModules: {
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      extraSpecialArgs = specialArgsFor host;
      users.${host.username}.imports = homeModules;
      backupFileExtension = ".bak";
    };
  };

  mkHost = platform: featureSelector: host: let
    inherit (platforms.${platform}) build homeManagerModule baseModules;

    features = featureSelector platform host;
    systemModules = modulesFor platform features;
    homeModules = modulesFor "home" features;
  in
    build {
      inherit (host) system;
      specialArgs = specialArgsFor host;
      modules =
        baseModules
        ++ systemModules
        ++ host.modules
        ++ lib.optionals (homeModules != []) [
          homeManagerModule
          (homeManagerConfig host homeModules)
        ];
    };
in {
  config.mzwing.lib = {
    inherit mkHost;

    mkDarwinHost = mkHost "darwin" selectFeatures;
    mkDarwinCIHost = mkHost "darwin" selectCIFeatures;
    mkNixosHost = mkHost "nixos" selectFeatures;
    mkNixosCIHost = mkHost "nixos" selectCIFeatures;
  };
}
