{
  mzwing.hosts.nixos.mzwing-upcloud-sg = {
    hostname = "mzwing-upcloud-sg";
    system = "x86_64-linux";
    type = "server";
    username = "mzwing";
    useremail = "mzwing@mzwing.eu.org";

    features = [
      "core/nix"
      "home/base"
      "nixos/server/base"
      "nixos/server/disko-vda-ext4"
      "nixos/server/ssh"
      "nixos/server/upcloud"
      "nixos/server/zram"
      "software/editor/neovim"
      "software/network/tailscale"
      "software/network/vpn"
      "software/security/gpg"
      "software/security/ssh"
      "software/server/caddy"
      "software/server/pumpkin"
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
