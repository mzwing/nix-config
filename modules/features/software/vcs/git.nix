let
  # git-cow calls git from PATH, so its own `worktree add` must reach the real git
  gitWithCow = pkgs: let
    inherit (pkgs) git;
    wrapper = pkgs.writeShellScript "git" ''
      if [ "''${1-}" = worktree ] && [ "''${2-}" = add ] && [ -z "''${GIT_COW_WRAPPED-}" ]; then
        shift 2
        GIT_COW_WRAPPED=1 exec ${pkgs.nur.repos.mzwing.git-cow}/bin/git-cow add "$@"
      fi
      exec ${git}/bin/git "$@"
    '';
  in
    pkgs.symlinkJoin {
      name = "git-with-cow-${git.version}";
      inherit (git) version meta;
      paths = [git];
      postBuild = ''
        rm $out/bin/git
        ln -s ${wrapper} $out/bin/git
      '';
    };
in {
  mzwing.features."software/vcs/git" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    packages.system = pkgs:
      with pkgs; [
        (gitWithCow pkgs)
        git-extras
        nur.repos.mzwing.git-cow
      ];

    home = {
      lib,
      pkgs,
      type,
      useremail,
      ...
    }: {
      home.activation.removeExistingGitconfig = lib.hm.dag.entryBefore ["checkLinkTargets"] ''
        rm -f ~/.gitconfig
      '';

      programs.git = {
        enable = true;
        package = gitWithCow pkgs;
        lfs.enable = true;

        signing = {
          key = null;
          # Containers hold no signing key
          signByDefault = type != "container";
          format = "openpgp";
        };

        includes = [
          {
            path = "~/work/.gitconfig";
            condition = "gitdir:~/work/";
          }
        ];

        settings =
          {
            user.email = useremail;
            # Not the login, which is root on containers
            user.name = "mzwing";

            init.defaultBranch = "master";
            trim.bases = "develop,master,main";
            push.autoSetupRemote = true;
            pull.rebase = true;
            log.date = "iso";

            color.ui = true;

            alias = {
              br = "branch";
              co = "checkout";
              st = "status";
              ls = "log --pretty=format:\"%C(yellow)%h%Cred%d\\\\ %Creset%s%Cblue\\\\ [%cn]\" --decorate";
              ll = "log --pretty=format:\"%C(yellow)%h%Cred%d\\\\ %Creset%s%Cblue\\\\ [%cn]\" --decorate --numstat";
              cm = "commit -m";
              ca = "commit -am";
              dc = "diff --cached";
              amend = "commit --amend -m";
              update = "submodule update --init --recursive";
              foreach = "submodule foreach";
            };
          }
          // lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
            credential.helper = "osxkeychain";
          };
      };
    };
  };
}
