{
  mzwing.features."software/network/sing-box" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    requires = ["darwin/homebrew"];

    packages.system = pkgs: [pkgs.nur.repos.mzwing.sing-box-alpha];

    darwin.homebrew.casks = ["sfm@alpha"];
  };
}
