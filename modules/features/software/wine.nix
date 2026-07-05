{
  mzwing.features."software/wine" = {
    # TODO: add nixos support
    meta.platforms = [
      "darwin"
    ];

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
