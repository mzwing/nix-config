{
  mzwing.features."software/development" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    requires = ["darwin/homebrew"];

    packages = {
      system = pkgs:
        with pkgs; [
          devenv
          devbox
          tokei
        ];

      darwin = pkgs: [pkgs.tuist];

      nixos = pkgs:
        with pkgs; [
          licensed
          jetbrains.idea
        ];
    };

    darwin.homebrew = {
      brews = [
        "licensed"
        "xcode-build-server"
      ];
      casks = [
        "openinterminal"
      ];
      masApps = {
        "Developer" = 640199958;
        "TestFlight" = 899247664;
        "Xcode" = 497799835;
      };
    };

    nixos.programs.ccache.enable = true;

    home = {
      lib,
      pkgs,
      ...
    }:
      lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
        programs.jetbrains-remote = {
          enable = true;
          ides = with pkgs.jetbrains; [
            idea
          ];
        };
      };
  };
}
