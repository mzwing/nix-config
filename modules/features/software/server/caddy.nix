{
  mzwing.features."software/server/caddy" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    packages.system = pkgs: [pkgs.caddy];
  };
}
