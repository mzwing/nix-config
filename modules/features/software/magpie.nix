{
  mzwing.features."software/magpie" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    requires = ["darwin/homebrew"];

    darwin.homebrew.casks = ["magpie-app"];

    nixos = {
      pkgs,
      type,
      ...
    }: {
      environment.systemPackages = [
        (pkgs.nur.repos.xyenon.magpie.override {guiSupport = type == "desktop";})
      ];
    };
  };
}
