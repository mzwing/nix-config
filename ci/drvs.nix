# Evaluated by mzwing/nix-actions' gc-store / store-cache/reconcile (default drvs-file input):
#   nix eval --impure --json --file ci/drvs.nix
# Full retention set across inactive configurations; the actions get the exact scheduled derivations separately.
# Same source as ci/outputs.nix: the CI variants behind .#legacyPackages.<sys>.ci, so retention never drifts from what CI builds.
let
  flake = builtins.getFlake "git+file://${toString ../.}";
  inherit (flake.inputs.nixpkgs) lib;
  variants = flake.legacyPackages."x86_64-linux".ci.variants;
in
  lib.mapAttrsToList (_: cfg: cfg.system.drvPath) variants.darwin
  ++ lib.mapAttrsToList (_: cfg: cfg.config.system.build.toplevel.drvPath) variants.nixos
