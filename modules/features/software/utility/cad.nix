{
  mzwing.features."software/utility/cad" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    requires = ["darwin/homebrew"];

    packages.nixos = pkgs: [pkgs.freecad];

    darwin.homebrew.casks = [
      "autocad"
      "freecad"
    ];
  };
}
