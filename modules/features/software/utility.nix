{
  mzwing.features."software/utility" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    requires = ["darwin/homebrew"];

    packages = {
      system = pkgs:
        with pkgs; [
          p7zip
          procps
          procs
          rclone
        ];

      darwin = pkgs: [pkgs.mas];

      nixos = pkgs: [pkgs.kdePackages.ark];
    };

    darwin.homebrew = {
      brews = [
        "mole"
      ];
      casks = [
        "jordanbaird-ice@beta"
        "karabiner-elements"
        "keepingyouawake"
        "keka"
        "kekaexternalhelper"
        "maccy"
        "stats"
        "easydict"
      ];
    };

    home = {
      programs.gh = {
        enable = true;
        gitCredentialHelper.enable = true;
        settings.git_protocol = "https";
      };
    };
  };
}
