# The baseline every NixOS server of mine shares. A profile is just a feature with no modules of its own.
{
  mzwing.features."profiles/nixos-server" = {
    meta.platforms = ["nixos"];

    requires = [
      "core/nix"
      "home/base"
      "nixos/server"
      "nixos/server/disko-vda-ext4"
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
  };
}
