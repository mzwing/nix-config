{
  mzwing.features."software/shell" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    requires = [
      "software/fish"
      "software/ghostty"
      "software/git"
      "software/gpg"
      "software/java"
      "software/ssh"
    ];

    packages = {
      system = pkgs:
        with pkgs; [
          any-nix-shell
          bind
          nur.repos.mzwing.haru
        ];

      darwin = pkgs:
        with pkgs; [
          bash
          iproute2mac
        ];
    };

    home = {pkgs, ...}: {
      programs = {
        fastfetch.enable = true;
        lazygit.enable = true;
        eza = {
          enable = true;
          git = true;
          icons = "auto";
          enableFishIntegration = true;
        };
        yazi = {
          enable = true;
          enableFishIntegration = true;
          settings.manager = {
            show_hidden = true;
            sort_dir_first = true;
          };
        };
        skim = {
          enable = true;
          enableFishIntegration = true;
        };
        fd = {
          enable = true;
          ignores = [
            ".git/"
            "node_modules/"
          ];
        };
        zoxide = {
          enable = true;
          enableFishIntegration = true;
        };
        fzf = {
          enable = true;
          enableFishIntegration = true;
        };
        man = {
          enable = true;
          package = pkgs.man;
        };
        bat.enable = true;
        btop.enable = true;
        jq.enable = true;
        ripgrep.enable = true;
        command-not-found.enable = false;
        nix-index = {
          enable = true;
          enableFishIntegration = true;
        };
        direnv = {
          enable = true;
          enableFishIntegration = true;
          nix-direnv.enable = true;
        };
        starship = {
          enable = true;
          enableFishIntegration = true;
          enableInteractive = false;
          enableTransience = true;
          presets = [
            "nerd-font-symbols"
            # "jetpack"
          ];
        };
      };
      home.shellAliases = {
        urldecode = "python3 -c 'import sys, urllib.parse as ul; print(ul.unquote_plus(sys.stdin.read()))'";
        urlencode = "python3 -c 'import sys, urllib.parse as ul; print(ul.quote_plus(sys.stdin.read()))'";
        nixfmt = "alejandra --exclude ./.devenv --exclude ./.devbox";
      };
    };
  };
}
