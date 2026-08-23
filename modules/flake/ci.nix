# What CI builds and caches: nix eval --json .#legacyPackages.x86_64-linux.ci.targets
# Under legacyPackages because `nix flake check` walks it without forcing its contents; a custom top-level output would just draw a warning.
# Same value whichever system you read it from.
{
  config,
  lib,
  ...
}: let
  # Hosts with local-only features stripped — see meta.ci.mode.
  variants = {
    darwin = lib.mapAttrs (_: config.mzwing.lib.mkDarwinCIHost) config.mzwing.hosts.darwin;
    nixos = lib.mapAttrs (_: config.mzwing.lib.mkNixosCIHost) config.mzwing.hosts.nixos;
  };

  # The one place that knows where each platform keeps its toplevel derivation.
  toplevelOf = {
    darwin = cfg: cfg.system;
    nixos = cfg: cfg.config.system.build.toplevel;
  };

  entriesFor = platform:
    lib.mapAttrsToList (name: cfg: {
      name = "${platform}.${name}";
      system = cfg.pkgs.stdenv.hostPlatform.system;
      drv = toplevelOf.${platform} cfg;
    })
    variants.${platform};

  entries = entriesFor "darwin" ++ entriesFor "nixos";

  targets =
    map (entry: {
      inherit (entry) name system;
      drvPath = entry.drv.drvPath;
      outputPath = entry.drv.outPath;
    })
    entries;
in {
  perSystem = {pkgs, ...}: {
    legacyPackages.ci = {
      inherit targets;
      inherit (config) systems;

      # The shims under ci/ read these, so they need no knowledge of the darwin/nixos split.
      bySystem = lib.genAttrs config.systems (system: map (entry: entry.drv) (lib.filter (entry: entry.system == system) entries));
      drvs = map (entry: entry.drv.drvPath) entries;
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
