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

    nixos = {
      lib,
      pkgs,
      type,
      ...
    }: {
      programs.ccache.enable = true;
      environment.systemPackages = lib.mkIf (type == "desktop") [pkgs.jetbrains.idea];
    };

    home = {
      lib,
      pkgs,
      type,
      ...
    }:
      lib.mkIf (pkgs.stdenv.hostPlatform.isLinux && type == "desktop") {
        programs.jetbrains-remote = {
          enable = true;
          ides = with pkgs.jetbrains; [
            idea
          ];
        };
      };
  };
}
