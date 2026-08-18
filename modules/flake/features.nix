# Resolving a host's feature names into modules.
{
  config,
  lib,
  ...
}: let
  inherit (lib) attrValues concatMap concatStringsSep filter optional;

  featureTable = config.mzwing.features;
  availableFeatures = builtins.attrNames featureTable;

  featureByName = name:
    featureTable.${name}
    or (throw "Unknown feature '${name}'. Available features: ${concatStringsSep ", " availableFeatures}");

  item = name: {
    key = name;
    value = featureByName name;
  };

  # genericClosure dedupes and terminates on cycles. Sorted by name afterwards so module order depends only on which features are selected — otherwise moving one into a profile would reshuffle every list-valued option.
  # Use mkBefore/mkAfter if you actually need ordering.
  closeOver = names:
    builtins.sort (a: b: a.name < b.name)
    (map (entry: entry.value) (builtins.genericClosure {
      startSet = map item names;
      operator = entry: map item entry.value.requires;
    }));

  # Without this a feature that does not apply to the host's platform resolves to a null module and silently vanishes.
  checkFeatures = platform: host: features: let
    problemsFor = feature: let
      declared = feature.meta.platforms;
      declaresPlatform = builtins.elem platform declared;
      # Profiles carry no modules, only `requires`.
      contributes =
        feature.${platform} != null || feature.home != null || feature.requires != [];
    in
      optional (declared == [])
      "feature '${feature.name}' declares no meta.platforms"
      ++ optional (declared != [] && !declaresPlatform)
      "feature '${feature.name}' does not apply to ${platform} (declares: ${concatStringsSep ", " declared})"
      ++ optional (declaresPlatform && !contributes)
      "feature '${feature.name}' claims ${platform} but provides neither a ${platform} nor a home module";

    problems = concatMap problemsFor features;
  in
    if problems == []
    then features
    else
      throw ''
        Host '${host.hostname}' selects features that do not fit ${platform}:
          - ${concatStringsSep "\n  - " problems}
      '';

  selectFeatures = platform: host: checkFeatures platform host (closeOver host.features);

  selectCIFeatures = platform: host:
    filter (feature: feature.meta.ci.mode != "local-only") (selectFeatures platform host);

  modulesFor = kind: features:
    map (feature: feature.${kind}) (filter (feature: feature.${kind} != null) features);

  moduleAttrsFor = kind:
    builtins.listToAttrs (
      map
      (feature: {
        inherit (feature) name;
        value = feature.${kind};
      })
      (filter (feature: feature.${kind} != null) (attrValues featureTable))
    );
in {
  config.mzwing.lib = {
    inherit
      selectFeatures
      selectCIFeatures
      modulesFor
      moduleAttrsFor
      ;
  };
}
