{
  mzwing.features."software/browser/safari" = {
    meta.platforms = ["darwin"];

    requires = ["darwin/homebrew"];

    darwin.homebrew = {
      casks = ["bewlycat"];
      masApps = {
        "uBlock Origin Lite" = 6745342698;
        "Userscripts" = 1463298887;
      };
    };
  };
}
