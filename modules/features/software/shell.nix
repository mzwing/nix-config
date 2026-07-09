let
  systemShellPackages = pkgs:
    with pkgs; [
      any-nix-shell
    ];
in {
  mzwing.features."software/shell" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    darwin = {pkgs, ...}: {
      environment.systemPackages =
        systemShellPackages pkgs
        ++ (with pkgs; [
          bash
          iproute2mac
        ]);
    };

    nixos = {pkgs, ...}: {
      environment.systemPackages = systemShellPackages pkgs;
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
      home.packages = [pkgs.any-nix-shell];
      home.shellAliases = {
        urldecode = "python3 -c 'import sys, urllib.parse as ul; print(ul.unquote_plus(sys.stdin.read()))'";
        urlencode = "python3 -c 'import sys, urllib.parse as ul; print(ul.quote_plus(sys.stdin.read()))'";
        nixfmt = "alejandra --exclude .devbox";
      };
    };
  };
}
