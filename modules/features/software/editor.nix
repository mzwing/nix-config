# The editors, and which of them wins.
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

    nixos = {
      # Root's shell and single-user mode see none of the above.
      programs.nano.enable = true;
    };

    home = {
      # Neovim wins, and this sets EDITOR. software/neovim only mkDefaults it, so servers taking it alone still get one.
      programs.neovim.defaultEditor = true;
    };
  };
}
