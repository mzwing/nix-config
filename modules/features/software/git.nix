let
  systemGitModule = {pkgs, ...}: {
    environment.systemPackages = with pkgs; [
      git
      git-extras
    ];
  };
in {
  mzwing.features."software/git" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    darwin = systemGitModule;
    nixos = systemGitModule;

    home = {
      lib,
      pkgs,
      username,
      useremail,
      ...
    }: {
      home.activation.removeExistingGitconfig = lib.hm.dag.entryBefore ["checkLinkTargets"] ''
        rm -f ~/.gitconfig
      '';

      programs.git = {
        enable = true;
        lfs.enable = true;

        signing = {
          key = null;
          signByDefault = true;
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
            user.name = username;

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
          // lib.optionalAttrs pkgs.stdenv.isDarwin {
            credential.helper = "osxkeychain";
          };
      };
    };
  };
}
