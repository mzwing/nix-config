{
  mzwing.features."software/fish" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    system = {
      pkgs,
      username,
      ...
    }: {
      programs.fish.enable = true;
      environment.shells = [pkgs.fish];
      users.users.${username}.shell = pkgs.fish;
    };

    home = {pkgs, ...}: {
      programs.fish = {
        enable = true;
        generateCompletions = true;
        plugins =
          map (x: {
            name = x.pname;
            src = x;
          }) (
            with pkgs.nur.repos.mzwing; [
              replay-fish
              getopts-fish
            ]
          )
          ++ map (x: {inherit (x) name src;}) (
            with pkgs.fishPlugins; [
              async-prompt
              autopair
              done
              fzf-fish
              wakatime-fish
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
