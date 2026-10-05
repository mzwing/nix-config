{
  mzwing.features."software/jujutsu" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    requires = ["software/git"];

    home = {
      config,
      lib,
      pkgs,
      ...
    }: {
      programs = {
        jujutsu = {
          enable = true;
          settings = {
            user = {inherit (config.programs.git.settings.user) name email;};

            # jj rewrites @ on every snapshot, so signing on rewrite would keep pinentry busy; sign once on push instead.
            signing = {
              behavior = "drop";
              backend = "gpg";
            };

            git = {
              sign-on-push = config.programs.git.signing.signByDefault;
              private-commits = "description(glob:'wip:*') | description(glob:'private:*')";
            };

            remotes.origin.auto-track-created-bookmarks = "*";

            revset-aliases."immutable_heads()" = "builtin_immutable_heads() | (trunk().. & ~mine())";

            templates.draft_commit_description = ''
              concat(
                builtin_draft_commit_description,
                "\nJJ: ignore-rest\n",
                diff.git(),
              )
            '';
          };
        };

        jjui.enable = true;

        difftastic = {
          enable = true;
          jujutsu.enable = true;
        };

        mergiraf = {
          enable = true;
          enableJujutsuIntegration = true;
        };

        starship.settings = {
          format = "$username$hostname$directory\${custom.jj}$all";
          # A `when` command would only be piped into jj-starship's stdin; its own non-zero exit outside repos hides the module.
          custom.jj = {
            when = true;
            shell = [(lib.getExe pkgs.jj-starship)];
            format = "($output )";
          };
          git_branch.disabled = true;
          # jj leaves Git's HEAD detached, so this would repeat the hash jj-starship already shows.
          git_commit.disabled = true;
          git_status.disabled = true;
        };
      };
    };
  };
}
