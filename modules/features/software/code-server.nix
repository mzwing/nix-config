{
  mzwing.features."software/code-server" = {
    meta.platforms = ["nixos"];

    requires = ["software/vscode"];

    home = {
      config,
      pkgs,
      ...
    }: {
      programs.vscodium = {
        package = pkgs.code-server;
        # With only the default profile Home Manager would make the dir mutable and run code-server during docker build.
        mutableExtensionsDir = false;
      };

      # CNB starts code-server on its own; this points it at the VSCodium directories software/vscode manages, away from the user dir CNB roams.
      xdg.configFile."code-server/config.yaml".text = ''
        user-data-dir: ${config.xdg.configHome}/VSCodium
        extensions-dir: ${config.home.homeDirectory}/.vscode-oss/extensions
      '';
    };
  };
}
