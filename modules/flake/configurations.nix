# The flake outputs describing my machines. Features that provide a module are also re-exported individually, for reuse from outside.
{
  config,
  lib,
  ...
}: {
  flake = {
    darwinConfigurations = lib.mapAttrs (_: config.mzwing.lib.mkDarwinHost) config.mzwing.hosts.darwin;
    nixosConfigurations = lib.mapAttrs (_: config.mzwing.lib.mkNixosHost) config.mzwing.hosts.nixos;

    darwinModules = config.mzwing.lib.moduleAttrsFor "darwin";
    nixosModules = config.mzwing.lib.moduleAttrsFor "nixos";
    homeModules = config.mzwing.lib.moduleAttrsFor "home";
  };
}
