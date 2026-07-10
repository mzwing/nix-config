{
  mzwing.hosts.nixos.mzwing-do-sgp = {
    hostname = "mzwing-do-sgp";
    system = "x86_64-linux";
    type = "server";
    username = "mzwing";
    useremail = "mzwing@mzwing.eu.org";
    features = [
      "core/nix"
      "home/base"
      "nixos/server/base"
      "nixos/server/digitalocean"
      "nixos/server/disko-vda-ext4"
      "nixos/server/network/do-sgp"
      "nixos/server/ssh"
      "nixos/server/zram"
      "software/fish"
      "software/git"
      "software/gpg"
      "software/neovim"
      "software/server"
      "software/shell"
      "software/vpn"
      "users/mzwing"
      "users/root"
    ];
    hardware = ./_hardware.nix;
  };
}
