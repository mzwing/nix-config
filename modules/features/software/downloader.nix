{
  mzwing.features."software/downloader" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    requires = ["darwin/homebrew"];

    packages = {
      system = pkgs:
        with pkgs; [
          aria2
          curl
          wget
        ];

      nixos = pkgs:
        with pkgs; [
          motrix-next
          nur.repos.xddxdd.baidunetdisk
        ];
    };

    darwin.homebrew = {
      casks = [
        "motrix-next"
        "thunder"
      ];
      masApps = {
        "百度网盘" = 547166701;
      };
    };
  };
}
