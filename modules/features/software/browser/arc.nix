{
  mzwing.features."software/browser/arc" = {
    meta.platforms = ["darwin"];

    requires = ["darwin/homebrew"];

    darwin.homebrew.casks = ["arc"];
  };
}
