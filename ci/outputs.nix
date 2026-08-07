# The derivations actually built by the coordinator's "Build CI
# configurations" step of .github/workflows/build.yml, restricted to the
# systems that have uncached targets. The system list is passed in via
# the BUILD_SYSTEMS environment variable as a JSON array:
#
#   BUILD_SYSTEMS='["x86_64-linux"]' nix build --impure --file ci/outputs.nix
#
# --impure is required for BUILD_SYSTEMS itself.
let
  flake = builtins.getFlake "path:${toString ../.}";
  inherit (flake.inputs.nixpkgs) lib;
  inherit (flake) ciConfigurations;

  systems = builtins.fromJSON (builtins.getEnv "BUILD_SYSTEMS");

  systemOf = cfg: cfg.pkgs.stdenv.hostPlatform.system;

  forSystem = system:
    lib.mapAttrsToList (_: cfg: cfg.system) (
      lib.filterAttrs (_: cfg: systemOf cfg == system) ciConfigurations.darwin
    )
    ++ lib.mapAttrsToList (_: cfg: cfg.config.system.build.toplevel) (
      lib.filterAttrs (_: cfg: systemOf cfg == system) ciConfigurations.nixos
    );
in
  lib.concatMap forSystem systems
