{
  mzwing.features."software/neovim" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    darwin = {pkgs, ...}: {
      environment.systemPackages = [pkgs.neovim];
      environment.variables.EDITOR = "nvim";
    };

    home = {
      home.sessionVariables.EDITOR = "nvim";

      programs.neovim = {
        enable = true;
        defaultEditor = true;
        viAlias = true;
        vimAlias = true;
        vimdiffAlias = true;
      };
    };
  };
}
