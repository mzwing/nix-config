{
  mzwing.hosts.nixos.mzwing-lycheen-us = {
    hostname = "mzwing-lycheen-us";
    system = "x86_64-linux";
    type = "server";
    username = "mzwing";
    useremail = "mzwing@mzwing.eu.org";
    site = "lycheen.openlist.service.mzwing.eu.org";

    # No provider feature: a plain QEMU guest, and _hardware.nix imports qemu-guest.nix itself
    features = [
      "core/nix"
      "home/base"
      "nixos/server/base"
      "nixos/server/ssh"
      "nixos/server/uefi"
      "nixos/server/zram"
      "software/ai/magpie"
      "software/editor/neovim"
      "software/network/sing-box"
      "software/security/gpg"
      "software/security/ssh"
      "software/server/caddy"
      "software/server/openlist"
      "software/shell"
      "software/vcs/git"
      "users/mzwing"
      "users/root"
    ];

    modules = [
      ./_disk.nix
      ./_hardware.nix
      ./_magpie.nix
      ./_network.nix
    ];
  };
}
