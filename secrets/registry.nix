# Names carry no .age suffix; it is added where needed.
let
  identities = import ../data/identities.nix;

  inherit (identities) hosts;
  inherit (identities.age) mzwing;

  # For a secret one host keeps to itself. Shared ones spell their readers out instead.
  ownedBy = host: [
    mzwing
    hosts.${host}
  ];
in {
  # `CLOUDFLARE_DNS_API_TOKEN=…`, a token that may edit the zone's DNS records for ACME challenges. Every host with a site belongs on this list.
  "cloudflare/dns-api-token" = {
    file = ./cloudflare/dns-api-token.age;
    recipients = [
      mzwing
      hosts.mzwing-azure
    ];
  };

  # caddy/<server>: Caddyfile sites of that server kept out of the repository, imported at runtime.
  "caddy/mzwing-azure" = {
    file = ./caddy/mzwing-azure.age;
    recipients = ownedBy "mzwing-azure";
  };

  "do-sgp/network/private" = {
    file = ./do-sgp/network/private.age;
    recipients = ownedBy "mzwing-do-sgp";
  };

  "do-sgp/network/public" = {
    file = ./do-sgp/network/public.age;
    recipients = ownedBy "mzwing-do-sgp";
  };

  # `EDGEONE_ORIGIN_AUTH=…`, the value EdgeOne's origin-pull rule sends as X-Origin-Auth. Every host with a site belongs on this list.
  "edgeone/origin-auth" = {
    file = ./edgeone/origin-auth.age;
    recipients = [
      mzwing
      hosts.mzwing-azure
    ];
  };

  # magpie/<server>/<client>: the key `magpie gateway-key add` printed on that server, for one machine without a gateway of its own.
  "magpie/mzwing-azure/mzwing-cnb" = {
    file = ./magpie/mzwing-azure/mzwing-cnb.age;
    recipients = ownedBy "mzwing-cnb";
  };

  "magpie/mzwing-huaweicloud-gz/mzwing-cnb" = {
    file = ./magpie/mzwing-huaweicloud-gz/mzwing-cnb.age;
    recipients = ownedBy "mzwing-cnb";
  };

  "magpie-web/mzwing-azure" = {
    file = ./magpie-web/mzwing-azure.age;
    recipients = ownedBy "mzwing-azure";
  };

  "magpie-web/mzwing-huaweicloud-gz" = {
    file = ./magpie-web/mzwing-huaweicloud-gz.age;
    recipients = ownedBy "mzwing-huaweicloud-gz";
  };

  "paseo/password" = {
    file = ./paseo/password.age;
    recipients = [
      mzwing
      hosts.mzwing-azure
    ];
  };

  # The sing-box client's, like subs-check/* below. The Mac reads them with the mzwing key, and every NixOS desktop selecting software/network/sing-box belongs on these lists.
  "sing-box/api-secret" = {
    file = ./sing-box/api-secret.age;
    recipients = [mzwing];
  };

  "sing-box/clash-api-secret" = {
    file = ./sing-box/clash-api-secret.age;
    recipients = [mzwing];
  };

  # sing-box/client/<name>: a whole sing-box fragment merged into every client profile, whose outbounds and endpoints join `proxy`.
  "sing-box/client/mzwing-azure-naive" = {
    file = ./sing-box/client/mzwing-azure-naive.age;
    recipients = [mzwing];
  };

  "sing-box/client/warp" = {
    file = ./sing-box/client/warp.age;
    recipients = [mzwing];
  };

  # sing-box/<server>/inbounds: that server's proxy inbounds as a whole sing-box fragment, ports included.
  "sing-box/mzwing-azure/inbounds" = {
    file = ./sing-box/mzwing-azure/inbounds.age;
    recipients = ownedBy "mzwing-azure";
  };

  # YAML merged over data/subs-check/config.yaml: the subscriptions and sub-store-path.
  "subs-check/config" = {
    file = ./subs-check/config.age;
    recipients = [mzwing];
  };

  # subs-check/self/<name>: a Clash node list checked alongside the subscriptions.
  "subs-check/self/haru" = {
    file = ./subs-check/self/haru.age;
    recipients = [mzwing];
  };

  "subs-check/self/mzwing-azure" = {
    file = ./subs-check/self/mzwing-azure.age;
    recipients = [mzwing];
  };

  "subs-check/self/sci" = {
    file = ./subs-check/self/sci.age;
    recipients = [mzwing];
  };

  # Every NixOS host selecting software/network/tailscale, or software/network/sing-box as a server, belongs on this list.
  "tailscale/oauth-secret" = {
    file = ./tailscale/oauth-secret.age;
    recipients = [
      mzwing
      hosts.mzwing-azure
      hosts.mzwing-cnb
      hosts.mzwing-huaweicloud-gz
    ];
  };

  "upcloud-sg/network/public-ipv4" = {
    file = ./upcloud-sg/network/public-ipv4.age;
    recipients = ownedBy "mzwing-upcloud-sg";
  };

  "upcloud-sg/network/public-ipv6" = {
    file = ./upcloud-sg/network/public-ipv6.age;
    recipients = ownedBy "mzwing-upcloud-sg";
  };

  "upcloud-sg/network/utility-ipv4" = {
    file = ./upcloud-sg/network/utility-ipv4.age;
    recipients = ownedBy "mzwing-upcloud-sg";
  };

  "wakatime/api-key" = {
    file = ./wakatime/api-key.age;
    recipients = [
      mzwing
      hosts.mzwing-azure
      hosts.mzwing-cnb
    ];
  };

  "wap/network/public" = {
    file = ./wap/network/public.age;
    recipients = ownedBy "mzwing-wap";
  };
}
