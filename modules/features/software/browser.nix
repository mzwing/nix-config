{
  mzwing.features."software/browser" = {
    meta.platforms = ["darwin"];

    darwin.homebrew = {
      casks = [
        "arc"
        "ungoogled-chromium"
        "zen"
      ];
      masApps = {
        "uBlock Origin Lite" = 6745342698;
        "Userscripts" = 1463298887;
      };
    };
  };
}
