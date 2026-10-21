{
  mzwing.features."software/system/wine" = {
    # TODO: add nixos support
    meta.platforms = [
      "darwin"
    ];

    requires = ["darwin/homebrew"];

    darwin = {
      homebrew.casks = [
        "crossover"
      ];
    };
  };
}
