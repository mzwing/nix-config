{
  mzwing.features."software/creative" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    requires = ["darwin/homebrew"];

    packages.nixos = pkgs:
      with pkgs; [
        blender
        kdePackages.kdenlive
        krita
        musescore
      ];

    darwin.homebrew = {
      casks = [
        "blender"
        "kdenlive"
        "krita"
        "musescore"
        "obs"
      ];
      masApps = {
        "库乐队" = 682658836;
        "iMovie 剪辑" = 408981434;
        "SeeMusic" = 1494196015;
      };
    };

    nixos.programs.obs-studio = {
      enable = true;
      enableVirtualCamera = true;
    };
  };
}
