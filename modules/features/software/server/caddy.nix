{
  mzwing.features."software/server/caddy" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    packages.system = pkgs: [pkgs.caddy];

    # A host with a site serves everything public through Caddy: the sites EdgeOne fronts, and the ones reached directly on the site name.
    nixos = {
      config,
      lib,
      pkgs,
      secrets,
      site,
      useremail,
      ...
    }: {
      options.services.caddy.virtualHosts = lib.mkOption {
        type = lib.types.attrsOf (lib.types.submodule ({
          config,
          name,
          ...
        }: {
          options.behindEdgeOne = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Whether EdgeOne fronts the site, so only requests carrying its origin secret get through.";
          };

          config = {
            useACMEHost = lib.mkDefault name;

            # EdgeOne Free publishes no origin ranges; the lock is a header it adds to every pull, whose value only it and this host know.
            extraConfig = lib.mkIf config.behindEdgeOne (lib.mkBefore ''
              @outsideEdgeOne not header X-Origin-Auth {$EDGEONE_ORIGIN_AUTH}
              abort @outsideEdgeOne
            '');
          };
        }));
      };

      config = lib.mkIf (site != null) {
        age.secrets = {
          cloudflare-dns-api-token = {
            file = secrets."cloudflare/dns-api-token";
            owner = "acme";
          };

          edgeone-origin-auth.file = secrets."edgeone/origin-auth";
        };

        security.acme = {
          acceptTerms = true;
          defaults = {
            email = useremail;
            # EdgeOne answers for the names it fronts, so only a DNS challenge works; the zone stays on Cloudflare.
            dnsProvider = "cloudflare";
            environmentFile = config.age.secrets.cloudflare-dns-api-token.path;
          };
        };

        services.caddy = {
          enable = true;
          package = pkgs.nur.repos.mzwing.caddy-naive;
          # Holds EDGEONE_ORIGIN_AUTH=…, out of the world-readable store.
          environmentFile = config.age.secrets.edgeone-origin-auth.path;
        };

        # 443/udp carries HTTP/3.
        networking.firewall = {
          allowedTCPPorts = [443];
          allowedUDPPorts = [443];
        };
      };
    };
  };
}
