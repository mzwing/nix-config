{
  mzwing.features."software/virtualization" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    requires = ["darwin/homebrew"];

    packages.darwin = pkgs: [pkgs.container];

    darwin.homebrew = {
      brews = [
        "container-compose"
      ];
      casks = [
        "orbstack"
        "utm"
      ];
      masApps = {
        "Windows App" = 1295203466;
      };
    };

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
