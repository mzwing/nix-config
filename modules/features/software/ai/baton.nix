{
  mzwing.features."software/ai/baton" = {
    meta.platforms = ["darwin" "nixos"];

    requires = [
      "home/agenix"
      "software/vcs/git"
    ];

    home = {
      config,
      hostname,
      inputs,
      lib,
      pkgs,
      secrets,
      system,
      ...
    }: let
      baton = inputs.baton.packages.${system}.default;
      interval = 3600;
      inherit (config.home) homeDirectory;
      dataDir =
        if pkgs.stdenv.hostPlatform.isDarwin
        then "${homeDirectory}/Library/Application Support/baton"
        else "${config.xdg.dataHome}/baton";
      cacheDir =
        if pkgs.stdenv.hostPlatform.isDarwin
        then "${homeDirectory}/Library/Caches/baton"
        else "${config.xdg.cacheHome}/baton";
      projects = "${homeDirectory}/repos";
      repoRoots = ["/Users/mzwing/repos" "/root/repos"];
      pathMap = lib.concatStringsSep ":" (map (root: "${root}=${projects}") (lib.filter (root: root != projects) repoRoots));
      agents =
        lib.optional (config.programs.omp.enable or false) "omp"
        ++ lib.optional (config.programs.pi-coding-agent.enable or false) "pi"
        ++ lib.optional (config.programs.claude-code.enable or false) "claude";
      credentialHelper = pkgs.writeShellScript "agent-history-credential" ''
        [ "$1" = get ] || exit 0
        echo username=cnb
        echo "password=$(cat "${config.age.secrets.agent-history-token.path}")"
      '';
      script = pkgs.writeShellApplication {
        name = "baton-sync";
        runtimeInputs = [baton pkgs.git pkgs.git-crypt pkgs.flock pkgs.coreutils];
        text = ''
          export BATON_HOME=${lib.escapeShellArg dataDir}
          export BATON_HOST=${lib.escapeShellArg hostname}
          export BATON_PROJECTS=${lib.escapeShellArg projects}
          export BATON_PATH_MAP=${lib.escapeShellArg pathMap}

          credentials=(-c credential.helper= -c credential.helper=${credentialHelper})
          repo() {
            git -C "$BATON_HOME" "''${credentials[@]}" -c commit.gpgsign=false "$@"
          }

          if [ ! -e "$BATON_HOME/.git" ]; then
            git "''${credentials[@]}" clone https://cnb.cool/MZWNET/agent-history.git "$BATON_HOME"
            (cd "$BATON_HOME" && git-crypt unlock "${config.age.secrets.baton-git-crypt-key.path}")
          fi

          baton import
          exec 9>"${cacheDir}/lock"
          flock 9
          repo add -A
          repo diff --cached --quiet || repo commit -q -m "sync from $BATON_HOST"
          repo pull -q --rebase
          repo push -q
          exec 9>&-
          ${lib.optionalString (agents != []) "baton materialize ${lib.concatMapStringsSep " " (agent: "--in ${agent}") agents}"}
        '';
      };
      loop = pkgs.writeShellScript "baton-sync-loop" ''
        while :; do
          ${lib.getExe script} || :
          sleep ${toString interval}
        done
      '';
    in {
      age.secrets.baton-git-crypt-key.file = secrets."baton/git-crypt-key";
      age.secrets.agent-history-token.file = secrets."cnb/agent-history-token";

      home.packages = [baton pkgs.git-crypt script];

      launchd.agents.baton-sync = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
        enable = true;
        config = {
          ProgramArguments = [(lib.getExe script)];
          StartInterval = interval;
          RunAtLoad = true;
          StandardOutPath = "${homeDirectory}/Library/Logs/baton-sync.log";
          StandardErrorPath = "${homeDirectory}/Library/Logs/baton-sync.log";
        };
      };

      systemd.user.services.baton-sync = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
        Unit.Description = "Sync agent sessions";
        Service.ExecStart = "${loop}";
        Install.WantedBy = ["default.target"];
      };
    };
  };
}
