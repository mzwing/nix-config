{
  mzwing.features."software/ctf" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    requires = ["darwin/homebrew"];

    packages.nixos = pkgs:
      with pkgs; [
        nur.repos.mzwing.packages.wsrx
        nur.repos.mzwing.packages.wsrx-desktop
      ];

    darwin.homebrew.casks = [
      "websocket-reflector-x"
    ];
  };
}
