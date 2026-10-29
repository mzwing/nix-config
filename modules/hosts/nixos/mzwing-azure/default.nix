{
  mzwing.hosts.nixos.mzwing-azure = {
    hostname = "mzwing-azure";
    system = "x86_64-linux";
    type = "server";
    username = "mzwing";
    useremail = "mzwing@mzwing.eu.org";
    site = "azure.openlist.service.mzwing.eu.org";

    features = [
      "core/nix"
      "home/base"
      "nixos/server/azure"
      "nixos/server/base"
      "nixos/server/ssh"
      "nixos/server/zram"
      "software/ai/magpie"
      "software/ai/mcp"
      "software/ai/skills"
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

    # No disko feature: the layout spans this VM's own pair of disks, so it lives next to the hardware it describes.
    modules = [
      ./_disk.nix
      ./_hardware.nix
      ./_network.nix
    ];
  };
}
