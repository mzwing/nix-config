# Build derivations of all CI targets, as a flat list of .drv paths (all
# systems). Evaluated by the coordinator's reconcile-builder-store-cache
# action in .github/workflows/build.yml:
#
#   nix eval --impure --json --file ci/drvs.nix
#
# Reconciliation expands their build-time closures for retention, uploads
# missing private outputs of the separately supplied scheduled derivations,
# and installs the deterministic keep-set used to prune stale Attic objects
# before GitHub Actions Cache saves them.
# The full list defines retention across inactive configurations; the action
# receives the exact scheduled derivations separately as its transfer set.
# See ci/targets.nix for why the flake is fetched via git+file: and why
# --impure is required.
let
  flake = builtins.getFlake "git+file://${toString ../.}";
  inherit (flake.inputs.nixpkgs) lib;
  ciConfigurations = import ./configurations.nix;
in
  lib.mapAttrsToList (_: cfg: cfg.system.drvPath) ciConfigurations.darwin
  ++ lib.mapAttrsToList (_: cfg: cfg.config.system.build.toplevel.drvPath) ciConfigurations.nixos
