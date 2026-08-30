{
  config,
  inputs,
  lib,
  ...
}: let
  inherit (config.mzwing.lib) modulesFor;

  secretPaths = lib.mapAttrs (_: entry: entry.file) (import ../../secrets/registry.nix);

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

  mkHost = platform: featureSelector: host: let
    inherit (platforms.${platform}) build homeManagerModule baseModules;

    specialArgs = {
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

    features = featureSelector platform host;
    homeModules = modulesFor "home" features;
  in
    build {
      inherit (host) system;
      inherit specialArgs;
      modules =
        baseModules
        ++ modulesFor platform features
        ++ host.modules
        ++ lib.optionals (homeModules != []) [
          homeManagerModule
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = specialArgs;
              users.${host.username}.imports = homeModules;
              backupFileExtension = ".bak";
            };
          }
        ];
    };
in {
  config.mzwing.lib.mkHosts = featureSelector: platform:
    lib.mapAttrs (_: mkHost platform featureSelector) config.mzwing.hosts.${platform};
}
