{
  mzwing.features."software/games/alpha-persei-cluster" = {
    meta.platforms = ["nixos"];

    nixos = {
      config,
      inputs,
      lib,
      ...
    }: let
      cfg = config.services.alpha-persei-cluster;
      tlsDir = "/run/alpha-persei-cluster-tls";
      # Same names as upstream's nginx template, plus the advertised IP the panel is opened on
      hosts = ["ys4fun.com" "*.ys4fun.com" "ys4fun.cn" "*.ys4fun.cn" "soboten.com" "*.soboten.com"] ++ lib.optional (cfg.hostIp != null) cfg.hostIp;
      site = scheme: extraConfig: {
        hostName = lib.concatMapStringsSep ", " (host: "${scheme}://${host}") hosts;
        logFormat = null;
        # The server takes the client address from X-Real-IP only when the peer is loopback
        extraConfig = ''
          ${extraConfig}
          reverse_proxy https://127.0.0.1:${toString cfg.httpsPort} {
            header_up X-Real-IP {remote_host}
            transport http {
              tls_server_name open.ys4fun.com
              tls_trust_pool file ${tlsDir}/sdk_ca.crt
            }
          }
        '';
      };
    in {
      imports = [inputs.alpha-persei-cluster.nixosModules.default];

      services.alpha-persei-cluster = {
        enable = true;
        webBind = "127.0.0.1";
        httpsPort = 18443;
        httpPort = 0;
      };

      services.caddy = {
        enable = true;
        # Browsers send no SNI for the panel's IP, and the tailnet arrives on the TUN address, which the certificate may not name
        globalConfig = "default_sni open.ys4fun.com";
        virtualHosts = {
          alpha-persei-cluster-https = site "https" "tls ${tlsDir}/sdk_cert.pem ${tlsDir}/sdk_key.pem";
          alpha-persei-cluster-http = site "http" "";
        };
      };

      # The server generates its certificates under its private state directory
      systemd.services.caddy = {
        wants = ["alpha-persei-cluster.service"];
        after = ["alpha-persei-cluster.service"];
        serviceConfig.BindReadOnlyPaths = ["/var/lib/alpha-persei-cluster/server/network/data:${tlsDir}"];
      };

      # systemd runs DynamicUser services as a static user of the same name, which sing-box's user rule can resolve
      users.users.alpha-persei-cluster = {
        isSystemUser = true;
        group = "alpha-persei-cluster";
      };
      users.groups.alpha-persei-cluster = {};

      # Its CDN fetches carry the ys4fun SNI, which the client rules would route back to this server
      services.sing-box.settings.route.rules = lib.mkIf config.services.sing-box.enable (lib.mkBefore [
        {
          user = ["alpha-persei-cluster"];
          action = "route";
          outbound = "direct";
        }
      ]);

      networking.firewall.interfaces.tailscale0 = {
        allowedTCPPorts = [80 443 cfg.gamePort];
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
