let
  systemDevelopmentPackages = pkgs:
    with pkgs; [
      devenv
      devbox
      tokei
    ];
in {
  mzwing.features."software/development" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    darwin = {pkgs, ...}: {
      environment.systemPackages =
        systemDevelopmentPackages pkgs
        ++ (with pkgs; [
          tuist
        ]);
      homebrew = {
        brews = [
          "licensed"
          "xcode-build-server"
        ];
        casks = [
          "clion"
          "openinterminal"
        ];
        masApps = {
          "Developer" = 640199958;
          "TestFlight" = 899247664;
          "Xcode" = 497799835;
        };
      };
    };

    nixos = {pkgs, ...}: {
      environment.systemPackages =
        systemDevelopmentPackages pkgs
        ++ (with pkgs; [
          licensed
          jetbrains.idea
        ]);
    };

    home = {
      lib,
      pkgs,
      ...
    }:
      lib.mkIf pkgs.stdenv.isLinux {
        programs.jetbrains-remote = {
          enable = true;
          ides = with pkgs.jetbrains; [
            idea
          ];
        };
      };
  };
}
