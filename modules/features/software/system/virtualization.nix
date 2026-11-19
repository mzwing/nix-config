{
  mzwing.features."software/system/virtualization" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    requires = ["darwin/homebrew" "darwin/qiuchenly"];

    packages.darwin = pkgs: [pkgs.container];

    darwin.homebrew = {
      brews = [
        "container-compose"
      ];
      casks = [
        "orbstack"
      ];
      masApps = {
        "Windows App" = 1295203466;
      };
    };

    darwin.mzwing.qiuchenly.apps."com.parallels.desktop.console".precracked = true;

    # TODO: complete podman configuration
    nixos = {pkgs, ...}: {
      virtualisation.vmware.host = {
        enable = true;
        extraPackages = with pkgs; [
          ntfs3g
        ];
      };
    };
  };
}
