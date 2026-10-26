{
  mzwing.features."software/games/heroic" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    requires = ["darwin/homebrew"];

    packages.nixos = pkgs: [pkgs.heroic];

    darwin.homebrew.casks = ["heroic"];
  };
}
