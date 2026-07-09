{
  mzwing.features."software/neovim" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    # TODO: Configure neovim completely.
    home = {
      inputs,
      pkgs,
      ...
    }: let
      typenix = inputs.typenix.packages.${pkgs.stdenv.hostPlatform.system}.default;
    in {
      programs.neovim = {
        enable = true;
        defaultEditor = true;
        viAlias = true;
        vimAlias = true;
        vimdiffAlias = true;
        extraPackages = with pkgs; [
          ast-grep
          luarocks
        ]
        ++ [
          typenix
        ];
        # TODO: Maybe here we can make typenix a neovim extension
        initLua = ''
          vim.filetype.add({
            pattern = {
              [".*/*.nix.d.ts"] = "nixts",
            },
          })

          pcall(vim.treesitter.language.register, "typescript", "nixts")

          if vim.lsp and vim.lsp.enable then
            vim.lsp.enable("typenix")
          end
        '';
      };

      xdg.configFile."nvim/lsp/typenix.lua".text = ''
        ---@type vim.lsp.Config
        return {
          cmd = function(dispatchers)
            return vim.lsp.rpc.start({ "${typenix}/bin/typenix", "--lsp", "--stdio" }, dispatchers)
          end,
          root_markers = { "tsconfig.json", "flake.nix", ".git" },
          filetypes = {
            "nix",
            "nixts",
          },
        }
      '';
    };
  };
}
