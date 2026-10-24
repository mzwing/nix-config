{
  mzwing.features."software/security/triwarden" = {
    meta.platforms = ["darwin"];

    requires = ["darwin/homebrew"];

    darwin.homebrew.casks = ["triwarden"];
  };
}
