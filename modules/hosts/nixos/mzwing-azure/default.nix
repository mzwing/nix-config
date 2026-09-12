{
  mzwing.hosts.nixos.mzwing-azure = {
    hostname = "mzwing-azure";
    system = "x86_64-linux";
    type = "server";
    username = "mzwing";
    useremail = "mzwing@mzwing.eu.org";

    features = [
      "profiles/nixos-server"
      "nixos/server/azure"
      "software/cliproxyapiplus"
      "software/nginx"
    ];

    # No disko feature: the layout spans this VM's own pair of disks, so it lives next to the hardware it describes.
    modules = [
      ./_disk.nix
      ./_hardware.nix
      ./_network.nix
    ];
  };
}
