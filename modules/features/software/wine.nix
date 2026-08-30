{
  mzwing.features."software/wine" = {
    # TODO: add nixos support
    meta.platforms = [
      "darwin"
    ];

    requires = ["darwin/homebrew"];

    darwin = {
      homebrew = {
        brews = [
          "crossover-trial-reset"
        ];
        casks = [
          "crossover"
        ];
      };
    };
  };
}
