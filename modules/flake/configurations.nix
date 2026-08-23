# The flake outputs: my machines, plus every feature module re-exported for reuse.
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
