{
  mzwing.hosts.nixos.mzwing-wap = {
    hostname = "mzwing-wap";
    system = "x86_64-linux";
    type = "server";
    username = "mzwing";
    useremail = "mzwing@mzwing.eu.org";

    # No provider feature: a plain QEMU guest, and _hardware.nix imports qemu-guest.nix itself.
    features = [
      "profiles/nixos-server"
    ];

    modules = [
      ./_hardware.nix
      ./_network.nix
    ];
  };
}
