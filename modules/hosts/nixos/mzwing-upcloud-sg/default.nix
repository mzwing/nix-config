{
  mzwing.hosts.nixos.mzwing-upcloud-sg = {
    hostname = "mzwing-upcloud-sg";
    system = "x86_64-linux";
    type = "server";
    username = "mzwing";
    useremail = "mzwing@mzwing.eu.org";

    features = [
      "profiles/nixos-server"
      "nixos/server/upcloud"
      "software/pumpkin"
    ];

    modules = [
      ./_hardware.nix
      ./_network.nix
    ];
  };
}
