{
  mzwing.hosts.nixos.mzwing-cnb = {
    hostname = "mzwing-cnb";
    system = "x86_64-linux";
    type = "workspace";
    # CNB runs everything in the workspace as root.
    username = "root";
    useremail = "mzwing@mzwing.eu.org";

    features = [
      "core/nix"
      "home/base"
      "network/china-mirrors"
      "software/code-server"
      "software/development"
      "software/neovim"
      "software/shell"
      "software/tailscale"
    ];

    modules = [
      ./_container.nix
    ];
  };
}
