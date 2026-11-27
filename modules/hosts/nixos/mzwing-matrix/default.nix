{
  mzwing.hosts.nixos.mzwing-matrix = {
    hostname = "mzwing-matrix";
    system = "x86_64-linux";
    type = "server";
    username = "mzwing";
    useremail = "mzwing@mzwing.eu.org";

    features = [
      "core/nix"
      "home/base"
      "network/china-mirrors"
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
      "software/development"
      "software/editor/neovim"
      "software/games/alpha-persei-cluster"
      "software/network/sing-box"
      "software/network/syncthing"
      "software/network/tools"
      "software/security/gpg"
      "software/security/ssh"
      "software/shell"
      "software/system/uptarn"
      "software/vcs"
      "ui/fonts"
      "users/mzwing"
      "users/root"
    ];

    modules = [
      ./_disk.nix
      ./_hardware.nix
      {
        age.identityPaths = ["/home/mzwing/.ssh/agenix"];
        mzwing.nix.unreachableSubstituters = [
          "https://mirror.sjtu.edu.cn/nix-channels/store"
          "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
        ];
        mzwing.sing-box = {
          role = "client";
          clientProfile = "matrix";
        };
        # Its tailnet address, which clients reach the game ports at; --host-ip only takes an IPv4
        services.alpha-persei-cluster.hostIp = "100.116.24.23";
        # networkd's SLAAC default keeps the EUI-64 address matrix.server.mzwing.eu.org points at
        networking.useNetworkd = true;
      }
    ];
  };
}
