# Names carry no .age suffix; it is added where needed.
let
  identities = import ../data/identities.nix;

  inherit (identities.age) mzwing;

  ownedBy = host: [
    mzwing
    identities.hosts.${host}
  ];
in {
  # One recipient covers both Mac readers: root and Home Manager both use ~/.ssh/agenix.
  "cliproxyapiplus/api-key" = {
    file = ./cliproxyapiplus/api-key.age;
    recipients = [mzwing];
  };

  "cliproxyapiplus/remote-secret-key" = {
    file = ./cliproxyapiplus/remote-secret-key.age;
    recipients = [mzwing];
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
}
