{
  mzwing.features."software/network" = {
    meta.platforms = [
      "darwin"
      "nixos"
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

    nixos = {pkgs, ...}: {
      environment.systemPackages = with pkgs; [
        bruno
        localsend
        wireshark
      ];
      programs.kdeconnect.enable = true;
    };

    home = {
      lib,
      pkgs,
      ...
    }:
      lib.mkIf pkgs.stdenv.isLinux {
        services.kdeconnect = {
          enable = true;
          indicator = true;
        };
      };
  };
}
