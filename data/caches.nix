# flake.nix's nixConfig repeats some of this and cannot import it; keep them in step by hand.
{
  # cache.nixos.org must stay listed: core/nix.nix applies this with mkForce, which replaces the module default instead of adding to it.
  defaultSubstituters = [
    "https://cache.nixos.org"
    "https://nix-community.cachix.org"
  ];

  # No cache.nixos.org key on purpose: nixpkgs and nix-darwin both define trusted-public-keys with it, and list settings concatenate.
  defaultPublicKeys = [
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
  ];

  extraSubstituters = [
    "https://cache.nixos-cuda.org"
    "https://cache.numtide.com"
  ];

  extraPublicKeys = [
    "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
    "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
  ];

  nur = {
    mzwing = {
      author = "mzwing";
      cache = {
        url = "https://cachix.service.mzwing.eu.org";
        publicKey = "mzwing.cachix.org-1:tOO3NqAwrXyPCnecEl/0wXwparCRksM5TeuS/wZK+KA=";
      };
    };

    so1ve = {
      author = "so1ve";
      cache = {
        url = "https://cache.so1ve.dev";
        publicKey = "cache.so1ve.dev-1:SijyzF9iE/VZwMXgMpd/HrNX9iItDZ1tdiNdeGakQGY=";
      };
    };
  };
}
