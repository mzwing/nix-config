{
  mzwing.features."software/cli" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

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

        gpg.enable = true;
      };

      services.gpg-agent = {
        enable = true;
        pinentry.package =
          if pkgs.stdenv.isDarwin
          then pkgs.pinentry_mac
          else pkgs.pinentry-curses;
        enableFishIntegration = true;
        enableSshSupport = true;
      };
    };
  };
}
