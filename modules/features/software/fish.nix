{
  mzwing.features."software/fish" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    home = {pkgs, ...}: {
      programs.fish = {
        enable = true;
        generateCompletions = true;
        plugins =
          [
            {
              name = "replay-fish";
              src = pkgs.fetchFromGitHub {
                owner = "jorgebucaran";
                repo = "replay.fish";
                rev = "d2ecacd3fe7126e822ce8918389f3ad93b14c86c";
                sha256 = "TzQ97h9tBRUg+A7DSKeTBWLQuThicbu19DHMwkmUXdg=";
              };
            }
            {
              name = "getopts-fish";
              src = pkgs.fetchFromGitHub {
                owner = "jorgebucaran";
                repo = "getopts.fish";
                rev = "e6f87012692088a0a9fea426f08e83001668ce66";
                sha256 = "vlIXBWCQrz2ZlxPhi2/+gweKnT6pcMQQ2NYlysqn7ig=";
              };
            }
            {
              name = "fish-async-prompt";
              src = pkgs.fetchFromGitHub {
                owner = "acomagu";
                repo = "fish-async-prompt";
                rev = "b90e8a8c6d1634d8f04f1532b164b99530445159";
                sha256 = "HWW9191RP//48HkAHOZ7kAAAPSBKZ+BW2FfCZB36Y+g=";
              };
            }
          ]
          ++ map (x: {inherit (x) name src;}) (
            with pkgs.fishPlugins; [
              done
              autopair
              fzf-fish
              z
            ]
          );
        shellAliases = {
          ".." = "cd ../";
          n = "nvim";
          ls = "eza --classify=auto --icons=auto --group-directories-first";
          l = "eza --classify=auto --icons=auto --group-directories-first -l";
          ll = "eza --classify=auto --icons=auto --group-directories-first -al";
          tree = "eza --classify=auto --icons=auto --tree";
          gg = "lazygit";
        };
        shellInit = "set -g fish_greeting";
        interactiveShellInit = ''
          any-nix-shell fish --info-right | source

          if set -q FISH_FORK_PWD_HINT
            if test (string match -r '^/' $FISH_FORK_PWD_HINT)
              cd $FISH_FORK_PWD_HINT
            end
          end

          if test -x /opt/homebrew/bin/brew
            /opt/homebrew/bin/brew shellenv | source

            if test -d (brew --prefix)"/share/fish/completions"
              set -p fish_complete_path (brew --prefix)/share/fish/completions
            end

            if test -d (brew --prefix)"/share/fish/vendor_completions.d"
              set -p fish_complete_path (brew --prefix)/share/fish/vendor_completions.d
            end
          end
        '';
      };
    };
  };
}
