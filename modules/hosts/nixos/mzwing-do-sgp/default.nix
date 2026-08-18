{
  mzwing.hosts.nixos.mzwing-do-sgp = {
    hostname = "mzwing-do-sgp";
    system = "x86_64-linux";
    type = "server";
    username = "mzwing";
    useremail = "mzwing@mzwing.eu.org";

    features = [
      "profiles/nixos-server"
      "nixos/server/digitalocean"
    ];

    modules = [
      ./_hardware.nix
      ./_network.nix
    ];
  };
}
