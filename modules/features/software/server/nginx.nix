{lib, ...}: let
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

  perRange = line: lib.concatMapStringsSep "\n" line cloudflareRanges;
in {
  mzwing.features."software/server/nginx" = {
    meta.platforms = ["nixos"];

    nixos = {
      config,
      secrets,
      ...
    }: {
      # Every named site is a record Cloudflare proxies, one label deep since that is all the zone's wildcard covers.
      options.services.nginx.virtualHosts = lib.mkOption {
        type = lib.types.attrsOf (lib.types.submodule (vhost: {
          config = lib.mkIf (!vhost.config.default) {
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
          };
        }));
      };

      config = {
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

          # Sites take images, videos and archives, and Cloudflare drops anything past 100M anyway.
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

          # Origin-IP scans and stray SNI get no certificate and no response.
          virtualHosts."_" = {
            default = true;
            rejectSSL = true;
            extraConfig = "return 444;";
          };
        };

        # No 80: with the Origin CA certificate Cloudflare only ever dials the origin over TLS.
        networking.firewall.allowedTCPPorts = [443];

        # Reloads once the pair is re-encrypted. Hashed, since the .age paths move with every change to the flake.
        systemd.services.nginx.reloadTriggers = map (secret: builtins.hashFile "sha256" secret.file) [
          config.age.secrets.cloudflare-origin-cert
          config.age.secrets.cloudflare-origin-key
        ];
      };
    };
  };
}
