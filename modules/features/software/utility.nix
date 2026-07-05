{
  mzwing.features."software/utility" = {
    meta.platforms = ["darwin"];

    darwin.homebrew = {
      brews = [
        "mole"
      ];
      casks = [
        "jordanbaird-ice@beta"
        "karabiner-elements"
        "keepingyouawake"
        "keka"
        "kekaexternalhelper"
        "maccy"
        "stats"
        "easydict"
      ];
      masApps = {
        "Bitwarden" = 1352778147;
      };
    };
  };
}
