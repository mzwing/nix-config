{
  mzwing.features."software/network" = {
    meta.platforms = ["darwin"];

    darwin.homebrew = {
      casks = [
        "proxyman"
        "wireshark-app"
      ];
      masApps = {
        "LocalSend" = 1661733229;
      };
    };
  };
}
