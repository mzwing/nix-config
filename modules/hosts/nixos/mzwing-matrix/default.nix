{
  mzwing.hosts.nixos.mzwing-matrix = {
    hostname = "mzwing-matrix";
    system = "x86_64-linux";
    type = "desktop";
    username = "mzwing";
    useremail = "mzwing@mzwing.eu.org";

    features = [
      "core/nix"
      "home/base"
      "network/china-mirrors"
      "nixos/desktop"
      "nixos/server/base"
      "nixos/server/ssh"
      "nixos/server/zram"
      "software/ai/baton"
      "software/ai/deja-vu"
      "software/ai/harness/omp"
      "software/ai/harness/pi-coding-agent"
      "software/ai/mcp"
      "software/ai/paseo"
      "software/ai/skills"
      "software/ai/tools"
      "software/browser/chromium"
      "software/browser/zen"
      "software/development"
      "software/editor/neovim"
      "software/editor/vscode"
      "software/editor/zed-editor"
      "software/network/sing-box"
      "software/network/syncthing"
      "software/network/tools"
      "software/security/bitwarden"
      "software/security/gpg"
      "software/security/ssh"
      "software/shell"
      "software/vcs"
      "ui/fonts"
      "users/mzwing"
      "users/root"
    ];

    modules = [
      ./_disk.nix
      ./_hardware.nix
      {
        mzwing.nix.unreachableSubstituters = [
          "https://mirror.sjtu.edu.cn/nix-channels/store"
          "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
        ];
        mzwing.sing-box.desktopProfile = "matrix";
        # matrix.server.mzwing.eu.org points at the EUI-64 address. NetworkManager.conf takes only the number here and silently falls back to stable-privacy on "eui64"
        networking.networkmanager.settings.connection."ipv6.addr-gen-mode" = 0;
      }
    ];
  };
}
