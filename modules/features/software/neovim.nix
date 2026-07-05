{
  mzwing.features."software/neovim" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    # TODO: Configure neovim completely.
    home = {pkgs, ...}: {
      programs.neovim = {
        enable = true;
        defaultEditor = true;
        viAlias = true;
        vimAlias = true;
        vimdiffAlias = true;
        extraPackages = with pkgs; [
          ast-grep
          luarocks
        ];
      };
    };
  };
}
