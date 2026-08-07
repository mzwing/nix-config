# Host configurations that CI builds and caches, as a flat list of
# {name, system, installable, outputPath} entries. Evaluated by the
# "Evaluate CI targets" step of .github/workflows/build.yml:
#
#   nix eval --json --file ci/targets.nix
let
  flake = builtins.getFlake "path:${toString ../.}";
  inherit (flake.inputs.nixpkgs) lib;
  inherit (flake) ciConfigurations;

  systemOf = cfg: cfg.pkgs.stdenv.hostPlatform.system;
in
  lib.mapAttrsToList (name: cfg: {
    name = "darwin.${name}";
    system = systemOf cfg;
    installable = ".#ciConfigurations.darwin.${name}.system";
    outputPath = cfg.system.outPath;
  })
  ciConfigurations.darwin
  ++ lib.mapAttrsToList (name: cfg: {
    name = "nixos.${name}";
    system = systemOf cfg;
    installable = ".#ciConfigurations.nixos.${name}.config.system.build.toplevel";
    outputPath = cfg.config.system.build.toplevel.outPath;
  })
  ciConfigurations.nixos
