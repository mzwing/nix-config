{
  mzwing.features."software/development" = {
    meta.platforms = ["darwin"];

    darwin.homebrew = {
      brews = [
        "licensed"
        "xcode-build-server"
      ];
      casks = [
        "bruno"
        "clion"
        "openinterminal"
        "tuist"
        "visual-studio-code"
      ];
      masApps = {
        "Developer" = 640199958;
        "TestFlight" = 899247664;
        "Xcode" = 497799835;
      };
    };
  };
}
