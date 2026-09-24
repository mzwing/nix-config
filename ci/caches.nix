# The caches core/nix.nix gives every host, mirrors aside. Evaluated by mzwing/nix-actions' plan-builds, whose `caches-file` input defaults to this path:
#   nix eval --json --file ci/caches.nix
let
  cacheData = import ../data/caches.nix;
  nurCaches = map (entry: entry.cache) (builtins.attrValues cacheData.nur);
in {
  substituters = cacheData.defaultSubstituters ++ cacheData.extraSubstituters ++ map (cache: cache.url) nurCaches;
  trustedPublicKeys = cacheData.defaultPublicKeys ++ cacheData.extraPublicKeys ++ map (cache: cache.publicKey) nurCaches;
}
