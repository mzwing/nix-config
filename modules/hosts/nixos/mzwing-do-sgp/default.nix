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
      "nixos/server/ssh"
      "nixos/server/zram"
      "software/editor/neovim"
      "software/network/tailscale"
      "software/network/vpn"
      "software/security/gpg"
      "software/security/ssh"
      "software/server/caddy"
      "software/shell"
      "software/vcs"
      "users/mzwing"
      "users/root"
    ];

    modules = [
      ./_hardware.nix
      ./_network.nix
    ];
  };
}
