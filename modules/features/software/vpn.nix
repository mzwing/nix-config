let
  systemVpnPackages = pkgs:
    with pkgs; [
      wgcf
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
        {
          name = "sing-box@alpha";
          link = true;
        }
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
          sing-box
          tailscale
        ]);
    };
  };
}
