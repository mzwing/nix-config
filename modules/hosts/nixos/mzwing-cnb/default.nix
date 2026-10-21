{
  mzwing.hosts.nixos.mzwing-cnb = {
    hostname = "mzwing-cnb";
    system = "x86_64-linux";
    type = "container";
    # CNB runs everything in the workspace as root.
    username = "root";
    useremail = "mzwing@mzwing.eu.org";

    features = [
      "core/nix"
      "home/base"
      "network/china-mirrors"
      "nixos/container"
      "software/ai/harness/mcp"
      "software/ai/harness/omp"
      "software/ai/harness/pi-coding-agent"
      "software/ai/harness/skills"
      "software/development/tools"
      "software/editor/neovim"
      "software/network/tailscale"
      "software/security/gpg"
      "software/security/ssh"
      "software/server/code-server"
      "software/shell"
      "software/vcs"
    ];

    modules = [
      ./_container.nix
    ];
  };
}
