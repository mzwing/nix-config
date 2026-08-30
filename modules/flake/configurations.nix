{config, ...}: let
  inherit (config.mzwing.lib) mkHosts moduleAttrsFor selectFeatures;
in {
  flake = {
    darwinConfigurations = mkHosts selectFeatures "darwin";
    nixosConfigurations = mkHosts selectFeatures "nixos";

    darwinModules = moduleAttrsFor "darwin";
    nixosModules = moduleAttrsFor "nixos";
    homeModules = moduleAttrsFor "home";
  };
}
