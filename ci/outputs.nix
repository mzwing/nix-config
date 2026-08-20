# Built by mzwing/nix-actions' build-targets (default file input). Kept despite the flake output because the action's default says so.
#   BUILD_SYSTEMS='["x86_64-linux"]' nix build --impure --file ci/outputs.nix
# Toplevels of the CI configurations (local-only stripped) restricted to BUILD_SYSTEMS, i.e. exactly the scheduled set from .#legacyPackages.<sys>.ci.targets.
# --impure for BUILD_SYSTEMS and the unlocked git+file: ref; CI checkouts are clean, so eval is deterministic per commit.
let
  flake = builtins.getFlake "git+file://${toString ../.}";
  inherit (flake.inputs.nixpkgs) lib;
  variants = flake.legacyPackages."x86_64-linux".ci.variants;

  systems = builtins.fromJSON (builtins.getEnv "BUILD_SYSTEMS");

  systemOf = cfg: cfg.pkgs.stdenv.hostPlatform.system;

  toplevel = {
    darwin = cfg: cfg.system;
    nixos = cfg: cfg.config.system.build.toplevel;
  };

  forSystem = system:
    lib.mapAttrsToList (_: cfg: toplevel.darwin cfg) (lib.filterAttrs (_: cfg: systemOf cfg == system) variants.darwin)
    ++ lib.mapAttrsToList (_: cfg: toplevel.nixos cfg) (lib.filterAttrs (_: cfg: systemOf cfg == system) variants.nixos);
in
  lib.concatMap forSystem systems
