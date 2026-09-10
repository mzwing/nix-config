{
  mzwing.features."profiles/nixos-server" = {
    meta.platforms = ["nixos"];

    # No disk layout: it follows the provider's device naming and firmware, so each host brings its own.
    requires = [
      "core/nix"
      "home/base"
      "nixos/server"
      "nixos/server/ssh"
      "nixos/server/zram"
      "software/neovim"
      "software/server"
      "software/shell"
      "software/vpn"
      "users/mzwing"
      "users/root"
    ];
  };
}
