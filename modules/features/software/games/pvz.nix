{
  mzwing.features."software/games/pvz" = {
    meta.platforms = ["darwin"];

    requires = ["darwin/homebrew"];

    darwin.homebrew.casks = ["pvz-portable"];
  };
}
