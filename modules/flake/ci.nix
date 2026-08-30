# Under legacyPackages because `nix flake check` walks it without forcing its contents.
{
  config,
  lib,
  ...
}: let
  inherit (config.mzwing.lib) mkHosts selectCIFeatures;

  variants = lib.genAttrs ["darwin" "nixos"] (mkHosts selectCIFeatures);

  toplevelOf = {
    darwin = cfg: cfg.system;
    nixos = cfg: cfg.config.system.build.toplevel;
  };

  entries =
    lib.concatMap (
      platform:
        lib.mapAttrsToList (name: cfg: {
          name = "${platform}.${name}";
          system = cfg.pkgs.stdenv.hostPlatform.system;
          drv = toplevelOf.${platform} cfg;
        })
        variants.${platform}
    )
    (lib.attrNames variants);

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

      bySystem = lib.genAttrs config.systems (system: map (entry: entry.drv) (lib.filter (entry: entry.system == system) entries));
      drvs = map (target: target.drvPath) targets;
    };

    # Forces every host to evaluate, which `nix flake check` skips for darwinConfigurations.
    checks.eval-all = pkgs.writeText "nix-config-eval-all" (
      lib.concatMapStrings
      (target: "${target.name} ${builtins.unsafeDiscardStringContext target.drvPath}\n")
      targets
    );
  };
}
