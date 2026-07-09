let
  systemEmailPackages = pkgs:
    with pkgs; [
      hydroxide
    ];
in {
  mzwing.features."software/email" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    darwin = {pkgs, ...}: {
      environment.systemPackages = systemEmailPackages pkgs;
      homebrew.casks = [
        "thunderbird"
      ];
    };

    nixos = {pkgs, ...}: {
      environment.systemPackages = systemEmailPackages pkgs;
      programs.thunderbird.enable = true;
    };
  };
}
