let
  systemServerModule = {pkgs, ...}: {
    environment.systemPackages = with pkgs; [
      caddy
    ];
  };
in {
  mzwing.features."software/server" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    darwin = systemServerModule;
    nixos = systemServerModule;
  };
}
