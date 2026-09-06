{
  mzwing.features."software/vpn" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    requires = ["darwin/homebrew"];

    packages = {
      system = pkgs:
        with pkgs; [
          nur.repos.mzwing.sing-box-alpha
        ];

      nixos = pkgs: [pkgs.tailscale];
    };

    darwin.homebrew.casks = [
      "sfm@alpha"
      "tailscale-app"
    ];
  };
}
