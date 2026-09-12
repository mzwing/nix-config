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
  # mzwing covers both Mac readers at once, since root and Home Manager there share ~/.ssh/agenix; each NixOS host running the service adds its own key.
  "cliproxyapiplus/api-key" = {
    file = ./cliproxyapiplus/api-key.age;
    recipients = [
      mzwing
      hosts.mzwing-azure
    ];
  };

  "cliproxyapiplus/remote-secret-key" = {
    file = ./cliproxyapiplus/remote-secret-key.age;
    recipients = [
      mzwing
      hosts.mzwing-azure
    ];
  };

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
    recipients = [mzwing];
  };

  "wap/network/public" = {
    file = ./wap/network/public.age;
    recipients = ownedBy "mzwing-wap";
  };
}
