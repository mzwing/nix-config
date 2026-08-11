{
  mzwing.features."software/ctf" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    darwin.homebrew.casks = [
      "websocket-reflector-x"
    ];

    nixos = {pkgs, ...}: {
      environment.systemPackages = with pkgs; [
        nur.repos.mzwing.packages.wsrx
        nur.repos.mzwing.packages.wsrx-desktop
      ];
    };
  };
}
