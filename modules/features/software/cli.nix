let
  systemCliPackages = pkgs:
    with pkgs; [
      any-nix-shell
      devenv
      devbox
      fastfetch
      nano
      p7zip
      procps
      procs
      rclone
      ripgrep
      starship
      tmux
      tokei
    ];

  systemCliModule = {pkgs, ...}: {
    environment.systemPackages = systemCliPackages pkgs;
  };
in {
  mzwing.features."software/cli" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    darwin = {pkgs, ...}: {
      environment.systemPackages =
        systemCliPackages pkgs
        ++ (with pkgs; [
          bash
          iproute2mac
          mas
        ]);
    };

    nixos = systemCliModule;

    home = {pkgs, ...}: {
      programs = {
        lazygit.enable = true;

        gh = {
          enable = true;
          gitCredentialHelper.enable = true;
          settings.git_protocol = "https";
        };

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
      };
    };
  };
}
