{
  mzwing.features."software/browser/yab" = {
    meta.platforms = ["darwin"];

    requires = ["darwin/homebrew"];

    darwin.homebrew.casks = ["yab"];
  };
}
