# Publishes the NUR data from data/caches.nix as an option, for features/core/nix.nix to read.
{lib, ...}: {
  options.mzwing.registry.nur = lib.mkOption {
    type = lib.types.attrsOf lib.types.raw;
    default = {};
    description = "NUR author registry with cache metadata.";
  };

  config.mzwing.registry.nur = (import ../../data/caches.nix).nur;
}
