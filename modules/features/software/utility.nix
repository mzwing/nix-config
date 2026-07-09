let
  systemUtilityPackages = pkgs:
    with pkgs; [
      p7zip
      procps
      procs
      rclone
    ];
in {
  mzwing.features."software/utility" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    darwin = {pkgs, ...}: {
      environment.systemPackages =
        systemUtilityPackages pkgs
        ++ (with pkgs; [
          mas
        ]);
      homebrew = {
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
        masApps = {
          "Bitwarden" = 1352778147;
        };
      };
    };

    nixos = {pkgs, ...}: {
      environment.systemPackages =
        systemUtilityPackages pkgs
        ++ (with pkgs; [
          kdePackages.ark
        ]);
      programs.nano.enable = true;
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
