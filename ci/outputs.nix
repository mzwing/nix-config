# Built by mzwing/nix-actions' build-targets, whose `file` input defaults to this path:
#   BUILD_SYSTEMS='["x86_64-linux"]' nix build --impure --file ci/outputs.nix
# CI toplevels restricted to BUILD_SYSTEMS — the scheduled set behind .#legacyPackages.<sys>.ci.targets.
# --impure for BUILD_SYSTEMS and the unlocked git+file: ref.
let
  flake = builtins.getFlake "git+file://${toString ../.}";
  inherit (flake.legacyPackages."x86_64-linux".ci) bySystem;

  systems = builtins.fromJSON (builtins.getEnv "BUILD_SYSTEMS");
in
  builtins.concatMap (system: bySystem.${system} or []) systems
