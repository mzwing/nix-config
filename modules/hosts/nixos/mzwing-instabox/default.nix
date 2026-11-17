{
  mzwing.hosts.nixos.mzwing-instabox = {
    hostname = "mzwing-instabox";
    system = "x86_64-linux";
    type = "container";
    # Container features decrypt system secrets through this user's agenix into /run/agenix, which takes root
    username = "root";
    useremail = "mzwing@mzwing.eu.org";

    features = [
      "core/nix"
      "home/base"
      "nixos/nspawn"
      "nixos/server/ssh"
      "software/ai/baton"
      "software/ai/harness/omp"
      "software/ai/harness/pi-coding-agent"
      "software/ai/mcp"
      "software/ai/deja-vu"
      "software/ai/paseo"
      "software/ai/skills"
      "software/development/tools"
      "software/editor/neovim"
      "software/network/syncthing"
      "software/network/tailscale"
      "software/security/gpg"
      "software/security/ssh"
      "software/shell"
      "software/vcs"
      "users/root"
    ];
  };
}
