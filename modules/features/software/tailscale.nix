let
  relayPort = 40000;
in {
  mzwing.features."software/tailscale" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    requires = ["darwin/homebrew"];

    darwin.homebrew.casks = ["tailscale-app"];

    nixos = {
      config,
      lib,
      secrets,
      type,
      ...
    }:
      lib.mkMerge [
        {
          services.tailscale = {
            enable = true;
            openFirewall = true;
            disableUpstreamLogging = true;
          };
        }

        (lib.mkIf (type == "server") {
          age.secrets.tailscale-oauth-secret.file = secrets."tailscale/oauth-secret";

          services.tailscale = {
            authKeyFile = config.age.secrets.tailscale-oauth-secret.path;
            # An OAuth secret registers ephemeral nodes by default, and those get deleted soon after going offline.
            authKeyParameters = {
              ephemeral = false;
              preauthorized = true;
            };
            extraUpFlags = ["--advertise-tags=tag:server"];
            extraSetFlags = ["--relay-server-port=${toString relayPort}"];
          };

          networking.firewall.allowedUDPPorts = [relayPort];
        })
      ];
  };
}
