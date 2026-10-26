{
  mzwing.features."software/games/minecraft/xmcl" = {
    meta.platforms = ["darwin"];

    requires = ["darwin/homebrew"];

    darwin.homebrew.casks = ["xmcl"];
  };
}
