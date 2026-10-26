{
  mzwing.hosts.nixos.mzwing-wap = {
    hostname = "mzwing-wap";
    system = "x86_64-linux";
    type = "server";
    username = "mzwing";
    useremail = "mzwing@mzwing.eu.org";

    # No provider feature: a plain QEMU guest, and _hardware.nix imports qemu-guest.nix itself.
    features = [
      "core/nix"
      "home/base"
      "nixos/server/base"
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
