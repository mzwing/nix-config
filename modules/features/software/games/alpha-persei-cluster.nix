{
  mzwing.features."software/games/alpha-persei-cluster" = {
    meta.platforms = ["nixos"];

    nixos = {
      config,
      inputs,
      ...
    }: let
      cfg = config.services.alpha-persei-cluster;
    in {
      imports = [inputs.alpha-persei-cluster.nixosModules.default];

      services.alpha-persei-cluster.enable = true;

      networking.firewall.interfaces.tailscale0 = {
        allowedTCPPorts = [cfg.httpPort cfg.httpsPort cfg.gamePort];
        allowedTCPPortRanges = [
          {
            from = cfg.gatewayPort;
            to = cfg.gatewayPort + 32;
          }
        ];
        allowedUDPPorts = [cfg.battlePort];
      };
    };
  };
}
