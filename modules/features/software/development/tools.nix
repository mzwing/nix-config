{
  mzwing.features."software/development/tools" = {
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

      nixos = pkgs: [pkgs.licensed];
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
  };
}
