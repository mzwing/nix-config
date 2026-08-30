{
  mzwing.features."software/network" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    requires = ["darwin/homebrew"];

    packages.nixos = pkgs:
      with pkgs; [
        bruno
        localsend
        wireshark
      ];

    darwin.homebrew = {
      casks = [
        "bruno"
        "proxyman"
        "soduto"
        "wireshark-app"
      ];
      masApps = {
        "LocalSend" = 1661733229;
      };
    };

    nixos.programs.kdeconnect.enable = true;

    home = {
      lib,
      pkgs,
      ...
    }:
      lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
        services.kdeconnect = {
          enable = true;
          indicator = true;
        };
      };
  };
}
