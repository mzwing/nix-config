# What CI builds and caches: nix eval --json .#legacyPackages.x86_64-linux.ci.targets
# Under legacyPackages because `nix flake check` walks it without forcing its contents; a custom top-level output would just draw a warning.
# Same value whichever system you read it from.
{
  config,
  lib,
  ...
}: let
  # Hosts with their local-only features stripped — see meta.ci.mode.
  ciConfigurations = {
    darwin = lib.mapAttrs (_: config.mzwing.lib.mkDarwinCIHost) config.mzwing.hosts.darwin;
    nixos = lib.mapAttrs (_: config.mzwing.lib.mkNixosCIHost) config.mzwing.hosts.nixos;
  };

  # The one place that knows where each platform keeps its toplevel derivation.
  toplevelOf = {
    darwin = cfg: cfg.system;
    nixos = cfg: cfg.config.system.build.toplevel;
  };

  targetsFor = platform:
    lib.mapAttrsToList (
      name: cfg: let
        drv = toplevelOf.${platform} cfg;
      in {
        name = "${platform}.${name}";
        system = cfg.pkgs.stdenv.hostPlatform.system;
        drvPath = drv.drvPath;
        outputPath = drv.outPath;
      }
    )
    ciConfigurations.${platform};

  targets = targetsFor "darwin" ++ targetsFor "nixos";
in {
  perSystem = {pkgs, ...}: {
    legacyPackages.ci = {
      inherit targets;
      inherit (config) systems;
    };

    # Forces every host to evaluate, which `nix flake check` otherwise never does for darwinConfigurations.
    # Context is discarded so this stays a text file rather than a build of every system.
    checks.eval-all = pkgs.writeText "nix-config-eval-all" (
      lib.concatMapStrings
      (target: "${target.name} ${builtins.unsafeDiscardStringContext target.drvPath}\n")
      targets
    );
  };
}
