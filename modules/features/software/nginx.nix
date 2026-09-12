let
  endpoint = import ../../../data/cliproxyapiplus.nix;

  # Cloudflare proxies the record, so this is the only name that ever reaches the origin. One label deep, because that is all the zone's wildcard covers.
  domain = "ai.mzwing.eu.org";

  # https://www.cloudflare.com/ips/ — Cloudflare announces changes in advance; refresh by hand.
  cloudflareRanges = [
    "173.245.48.0/20"
    "103.21.244.0/22"
    "103.22.200.0/22"
    "103.31.4.0/22"
    "141.101.64.0/18"
    "108.162.192.0/18"
    "190.93.240.0/20"
    "188.114.96.0/20"
    "197.234.240.0/22"
    "198.41.128.0/17"
    "162.158.0.0/15"
    "104.16.0.0/13"
    "104.24.0.0/14"
    "172.64.0.0/13"
    "131.0.72.0/22"
    "2400:cb00::/32"
    "2606:4700::/32"
    "2803:f800::/32"
    "2405:b500::/32"
    "2405:8100::/32"
    "2a06:98c0::/29"
    "2c0f:f248::/32"
  ];

  perRange = line: builtins.concatStringsSep "\n" (map line cloudflareRanges);
in {
  mzwing.features."software/nginx" = {
    meta.platforms = ["nixos"];

    requires = ["software/cliproxyapiplus"];

    nixos = {
      config,
      secrets,
      ...
    }: {
      # nginx runs as its own user, not root, so it has to own both halves itself.
      age.secrets = {
        cloudflare-origin-cert = {
          file = secrets."cloudflare/origin-cert";
          owner = "nginx";
          group = "nginx";
        };

        cloudflare-origin-key = {
          file = secrets."cloudflare/origin-key";
          owner = "nginx";
          group = "nginx";
        };
      };

      services.nginx = {
        enable = true;

        recommendedGzipSettings = true;
        recommendedOptimisation = true;
        recommendedProxySettings = true;
        recommendedTlsSettings = true;

        # Image and video endpoints carry real payloads, and Cloudflare drops anything past 100M anyway.
        clientMaxBodySize = "100m";

        commonHttpConfig = ''
          ${perRange (range: "set_real_ip_from ${range};")}
          real_ip_header CF-Connecting-IP;

          # $realip_remote_addr is the peer nginx actually accepted, before the header above replaced it.
          geo $realip_remote_addr $from_cloudflare {
            default 0;
            ${perRange (range: "${range} 1;")}
          }
        '';

        virtualHosts = {
          # Origin-IP scans and stray SNI get no certificate and no response.
          "_" = {
            default = true;
            rejectSSL = true;
            extraConfig = "return 444;";
          };

          ${domain} = {
            onlySSL = true;

            # Cloudflare's Origin CA issued this; no public trust store accepts it, which is the point.
            sslCertificate = config.age.secrets.cloudflare-origin-cert.path;
            sslCertificateKey = config.age.secrets.cloudflare-origin-key.path;

            # Whoever found the origin IP and forged the SNI is routing around the edge; give it nothing.
            extraConfig = ''
              if ($from_cloudflare = 0) {
                return 444;
              }
            '';

            locations."/" = {
              # 127.0.0.1, not endpoint.host: nginx resolves "localhost" once at startup and may land on a ::1 the service never binds.
              proxyPass = "http://127.0.0.1:${toString endpoint.port}";

              # /v1/realtime, /v1/responses and the panel's log stream all upgrade.
              proxyWebsockets = true;

              # One proxy_set_header here drops every inherited one, so this block owns the whole set.
              recommendedProxySettings = false;

              extraConfig = ''
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                # $remote_addr, not $proxy_add_x_forwarded_for: the management gate reads this to decide who is local, and a client-sent hop would forge 127.0.0.1 past it.
                proxy_set_header X-Forwarded-For $remote_addr;
                proxy_set_header X-Forwarded-Proto $scheme;
                proxy_set_header X-Forwarded-Host $host;

                # Token-at-a-time SSE: nothing may wait in a buffer.
                proxy_buffering off;
                proxy_request_buffering off;

                # A model can think for minutes before the first token.
                proxy_read_timeout 1h;
                proxy_send_timeout 1h;
              '';
            };
          };
        };
      };

      # No 80: with the Origin CA certificate Cloudflare only ever dials the origin over TLS.
      networking.firewall.allowedTCPPorts = [443];

      # The store path moves whenever the pair is re-encrypted, so a rekey reloads nginx.
      systemd.services.nginx.reloadTriggers = [
        config.age.secrets.cloudflare-origin-cert.file
        config.age.secrets.cloudflare-origin-key.file
      ];
    };
  };
}
