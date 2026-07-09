let
  systemDownloaderPackages = pkgs:
    with pkgs; [
      aria2
      curl
      wget
    ];
in {
  mzwing.features."software/downloader" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    darwin = {pkgs, ...}: {
      environment.systemPackages = systemDownloaderPackages pkgs;
      homebrew = {
        casks = [
          "motrix-next"
          "thunder"
        ];
        masApps = {
          "百度网盘" = 547166701;
        };
      };
    };

    nixos = {pkgs, ...}: {
      environment.systemPackages =
        systemDownloaderPackages pkgs
        ++ (with pkgs; [
          motrix-next
          nur.repos.xddxdd.baidunetdisk
        ]);
    };
  };
}
