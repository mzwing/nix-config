{
  config,
  inputs,
  lib,
  self,
  ...
}: let
  inherit (lib) attrValues filter optional;

  availableFeatures = builtins.attrNames config.mzwing.features;

  missingMessage = kind: name: available: "Unknown ${kind} '${name}'. Available ${kind}s: ${lib.concatStringsSep ", " available}";

  featureByName = feature:
    config.mzwing.features.${feature} or (throw (missingMessage "feature" feature availableFeatures));

  selectFeatures = host: map featureByName host.features;

  selectCIFeatures = host:
    filter
    (feature: feature.meta.ci.mode != "local-only")
    (selectFeatures host);

  modulesFor = kind: features:
    map (feature: feature.${kind}) (filter (feature: feature.${kind} != null) features);

  moduleAttrsFor = kind:
    builtins.listToAttrs (
      map
      (feature: {
        name = feature.name;
        value = feature.${kind};
      })
      (filter (feature: feature.${kind} != null) (attrValues config.mzwing.features))
    );

  specialArgsFor = host: {
    inherit inputs self;
    flake = self;
    inherit
      (host)
      hostname
      system
      type
      username
      useremail
      ;
  };

  homeManagerModule = hmInput: host: homeModules: {
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      extraSpecialArgs = specialArgsFor host;
      users.${host.username}.imports = homeModules;
      backupFileExtension = ".bak";
    };
  };

  mkDarwinHostWith = featureSelector: host: let
    features = featureSelector host;
    darwinModules = modulesFor "darwin" features;
    homeModules = modulesFor "home" features;
  in
    inputs.darwin.lib.darwinSystem {
      inherit (host) system;
      specialArgs = specialArgsFor host;
      modules =
        darwinModules
        ++ optional (homeModules != []) inputs.home-manager-darwin.darwinModules.home-manager
        ++ optional (homeModules != []) (homeManagerModule inputs.home-manager-darwin host homeModules);
    };

  mkNixosHostWith = featureSelector: host: let
    features = featureSelector host;
    nixosModules = modulesFor "nixos" features;
    homeModules = modulesFor "home" features;
  in
    inputs.nixpkgs.lib.nixosSystem {
      inherit (host) system;
      specialArgs = specialArgsFor host;
      modules =
        [
          inputs.agenix.nixosModules.default
          inputs.disko.nixosModules.disko
        ]
        ++ nixosModules
        ++ optional (host.hardware != null) host.hardware
        ++ optional (homeModules != []) inputs.home-manager-nixos.nixosModules.home-manager
        ++ optional (homeModules != []) (homeManagerModule inputs.home-manager-nixos host homeModules);
    };

  mkDarwinHost = mkDarwinHostWith selectFeatures;
  mkDarwinCIHost = mkDarwinHostWith selectCIFeatures;
  mkNixosHost = mkNixosHostWith selectFeatures;
  mkNixosCIHost = mkNixosHostWith selectCIFeatures;
in {
  config.mzwing.lib = {
    inherit
      selectFeatures
      selectCIFeatures
      modulesFor
      moduleAttrsFor
      mkDarwinHost
      mkDarwinCIHost
      mkNixosHost
      mkNixosCIHost
      ;
  };
}
