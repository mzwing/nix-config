{
  mzwing.features."software/editor" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    requires = [
      "software/neovim"
      "software/vscode"
      "software/zed-editor"
    ];

    nixos.programs.nano.enable = true;

    home.programs.neovim.defaultEditor = true;
  };
}
