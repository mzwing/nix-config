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
  # One Origin CA pair for the whole zone (*.mzwing.eu.org), so every host that terminates TLS for it belongs on these lists.
  "cloudflare/origin-cert" = {
    file = ./cloudflare/origin-cert.age;
    recipients = [
      mzwing
      hosts.mzwing-azure
    ];
  };

  "cloudflare/origin-key" = {
    file = ./cloudflare/origin-key.age;
    recipients = [
      mzwing
      hosts.mzwing-azure
    ];
  };

  "do-sgp/network/private" = {
    file = ./do-sgp/network/private.age;
    recipients = ownedBy "mzwing-do-sgp";
  };

  "do-sgp/network/public" = {
    file = ./do-sgp/network/public.age;
    recipients = ownedBy "mzwing-do-sgp";
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

  # Every NixOS host selecting software/network/tailscale belongs on this list.
  "tailscale/oauth-secret" = {
    file = ./tailscale/oauth-secret.age;
    recipients = [
      mzwing
      hosts.mzwing-azure
      hosts.mzwing-cnb
      hosts.mzwing-do-sgp
      hosts.mzwing-huaweicloud-gz
      hosts.mzwing-upcloud-sg
      hosts.mzwing-wap
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
