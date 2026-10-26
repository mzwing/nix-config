{
  mzwing.hosts.nixos.mzwing-huaweicloud-gz = {
    hostname = "mzwing-huaweicloud-gz";
    system = "x86_64-linux";
    type = "server";
    username = "mzwing";
    useremail = "mzwing@mzwing.eu.org";

    # No provider feature: an ECS is a plain QEMU guest, and _hardware.nix imports qemu-guest.nix itself.
    features = [
      "core/nix"
      "home/base"
      "network/china-mirrors"
      "nixos/server/base"
      "nixos/server/disko-vda-ext4"
      "nixos/server/ssh"
      "nixos/server/zram"
      "software/ai/magpie"
      "software/editor/neovim"
      "software/network/tailscale"
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
      ./_swap.nix
    ];
  };
}
