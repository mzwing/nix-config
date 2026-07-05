let
  systemEmailPackages = pkgs:
    with pkgs; [
      hydroxide
    ];

  systemEmailModule = {pkgs, ...}: {
    environment.systemPackages = systemEmailPackages pkgs;
  };
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

    nixos = systemEmailModule;
  };
}
