let
  identities = import ../../../data/identities.nix;
in {
  mzwing.features."users/root" = {
    meta.platforms = ["nixos"];

    nixos = {
      users.users.root.openssh.authorizedKeys.keys = [
        identities.users.mzwing
      ];
    };
  };
}
