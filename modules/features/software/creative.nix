{
  mzwing.features."software/creative" = {
    meta.platforms = [
      "darwin"
      "nixos"
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

    nixos = {pkgs, ...}: {
      environment.systemPackages = with pkgs; [
        blender
        kdePackages.kdenlive
        krita
        musescore
      ];
      programs.obs-studio = {
        enable = true;
        enableVirtualCamera = true;
      };
    };
  };
}
