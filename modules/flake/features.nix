{
  config,
  lib,
  ...
}: let
  inherit (lib) attrNames attrValues concatMap concatStringsSep elem filter hasPrefix listToAttrs optional sort;

  featureTable = config.mzwing.features;

  featureNames = attrNames featureTable;

  item = name: {
    key = name;
    value = featureTable.${name};
  };

  appliesTo = platform: name: elem platform featureTable.${name}.meta.platforms;

  # A name selects its own feature and every one beneath it, so a directory's name selects all of it. Those beneath are dropped where they do not apply.
  expand = platform: name: let
    own = optional (featureTable ? ${name}) name;
    beneath = filter (hasPrefix "${name}/") featureNames;
  in
    if own == [] && beneath == []
    then throw "Unknown feature '${name}'. Available features: ${concatStringsSep ", " featureNames}"
    else own ++ filter (appliesTo platform) beneath;

  # Sorted by name so module order does not depend on where a feature was selected from; use mkBefore/mkAfter if you need ordering.
  closeOver = platform: names:
    sort (a: b: a.name < b.name)
    (map (entry: entry.value) (builtins.genericClosure {
      startSet = map item (concatMap (expand platform) names);
      # Requirements that do not apply here are dropped, so a cross-platform feature can require a darwin-only one.
      operator = entry: map item (filter (appliesTo platform) (concatMap (expand platform) entry.value.requires));
    }));

  # Nested exactly as types.deferredModule nests its own: modules are flattened breadth-first, so depth decides merge order.
  packagesModule = kind: feature: fns: {
    imports = [
      (lib.setDefaultModuleLocation ''mzwing.features."${feature.name}".packages''
        ({pkgs, ...}: let
          collected = concatMap (fn: fn pkgs) fns;
        in
          if kind == "home"
          then {home.packages = collected;}
          else {environment.systemPackages = collected;}))
    ];
  };

  fragmentsFor = kind: feature: let
    fns = filter (fn: fn != null) (
      if kind == "home"
      then [feature.packages.home]
      else [feature.packages.system feature.packages.${kind}]
    );
  in
    optional (kind != "home" && feature.system != null) feature.system
    ++ optional (feature.${kind} != null) feature.${kind}
    ++ optional (fns != []) (packagesModule kind feature fns);

  modulesFor = kind: features: concatMap (fragmentsFor kind) features;

  moduleAttrsFor = kind:
    listToAttrs (
      filter (entry: entry.value.imports != [])
      (map (feature: {
        inherit (feature) name;
        value.imports = fragmentsFor kind feature;
      }) (attrValues featureTable))
    );

  checkFeatures = platform: host: features: let
    problemsFor = feature: let
      declared = feature.meta.platforms;
      declaresPlatform = elem platform declared;
      contributes =
        fragmentsFor platform feature
        != []
        || fragmentsFor "home" feature != []
        || feature.requires != [];
    in
      optional (declared == [])
      "feature '${feature.name}' declares no meta.platforms"
      ++ optional (declared != [] && !declaresPlatform)
      "feature '${feature.name}' does not apply to ${platform} (declares: ${concatStringsSep ", " declared})"
      ++ optional (declaresPlatform && !contributes)
      "feature '${feature.name}' claims ${platform} but contributes nothing";

    problems = concatMap problemsFor features;
  in
    if problems == []
    then features
    else
      throw ''
        Host '${host.hostname}' selects features that do not fit ${platform}:
          - ${concatStringsSep "\n  - " problems}
      '';

  selectFeatures = platform: host: checkFeatures platform host (closeOver platform host.features);

  selectCIFeatures = platform: host:
    filter (feature: feature.meta.ci.mode != "local-only") (selectFeatures platform host);
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
