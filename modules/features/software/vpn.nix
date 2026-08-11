let
  systemVpnPackages = pkgs:
    with pkgs; [
      wgcf
      nur.repos.mzwing.sing-box-alpha
    ];
in {
  mzwing.features."software/vpn" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    darwin = {pkgs, ...}: {
      environment.systemPackages = systemVpnPackages pkgs;
      homebrew.brews = [
        "cloudflarewarpspeedtest"
      ];
      homebrew.casks = [
        "sfm@alpha"
        "tailscale-app"
      ];
    };

    nixos = {pkgs, ...}: {
      environment.systemPackages =
        systemVpnPackages pkgs
        ++ (with pkgs; [
          tailscale
        ]);
    };
  };
}
