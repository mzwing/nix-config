{
  mzwing.features."software/server" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    packages.system = pkgs: [pkgs.caddy];
  };
}
