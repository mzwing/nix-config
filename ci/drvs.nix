# Build derivations of all CI targets, as a flat list of .drv paths (all
# systems). Evaluated by the "Garbage-collect stale store paths" step of
# the "cache" job in .github/workflows/build.yml:
#
#   nix eval --impure --json --file ci/drvs.nix
#
# The build-time closures of these derivations are registered as GC roots
# on the builder store cache machine before it collects everything else
# (stale intermediates from previous locks). See ci/targets.nix for why
# the flake is fetched via git+file: and why --impure is required.
let
  flake = builtins.getFlake "git+file://${toString ../.}";
  inherit (flake.inputs.nixpkgs) lib;
  ciConfigurations = import ./configurations.nix;
in
  lib.mapAttrsToList (_: cfg: cfg.system.drvPath) ciConfigurations.darwin
  ++ lib.mapAttrsToList (_: cfg: cfg.config.system.build.toplevel.drvPath) ciConfigurations.nixos
