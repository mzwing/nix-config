# Substituters and their public keys. Plain data, outside modules/ because import-tree would treat it as a flake-parts module.
# flake.nix's nixConfig repeats some of this and cannot import it; keep them in step by hand.
# features/core/nix.nix assembles the layers as mirror ++ default ++ extra ++ nur.
{
  # cache.nixos.org must stay listed: core/nix.nix applies this with mkForce, which replaces the module default instead of adding to it.
  defaultSubstituters = [
    "https://cache.nixos.org"
    "https://nix-community.cachix.org"
  ];

  # No cache.nixos.org key on purpose: these feed extra-trusted-public-keys, which appends. Assigning trusted-public-keys directly would replace the default and lose it.
  defaultPublicKeys = [
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
  ];

  # Useful but not universal, so they sit behind the public caches.
  extraSubstituters = [
    "https://cache.nixos-cuda.org"
  ];

  extraPublicKeys = [
    "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
  ];

  # Only xddxdd's is Attic; the other two are Cachix. Hence `cache`, not `attic`.
  nur = {
    xddxdd = {
      author = "xddxdd";
      cache = {
        url = "https://attic.xuyh0120.win/lantian";
        publicKey = "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc=";
      };
    };

    mzwing = {
      author = "mzwing";
      cache = {
        url = "https://mzwing.cachix.org";
        publicKey = "mzwing.cachix.org-1:tOO3NqAwrXyPCnecEl/0wXwparCRksM5TeuS/wZK+KA=";
      };
    };

    so1ve = {
      author = "so1ve";
      cache = {
        url = "https://so1ve.cachix.org";
        publicKey = "so1ve.cachix.org-1:51jcW4FkJhiLcqPsiUx3nglRP469les8F9zjFxio1nw=";
      };
    };
  };
}
