let
  agentContext = import ../../../../../data/agent-context.nix;
in {
  mzwing.features."software/ai/harness/claude-code" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    requires = [
      "darwin/homebrew"
      "home/agenix"
      # `hooks` below reads programs.gryph.
      "software/ai/gryph"
      # The wakatime plugin below only tracks once ~/.wakatime.cfg carries the key.
      "software/development/wakatime"
    ];

    home = {
      config,
      inputs,
      lib,
      pkgs,
      secrets,
      system,
      ...
    }: let
      inherit (pkgs.nur.repos.mzwing) claude-code-wakatime claude-hud;

      jsonFormat = pkgs.formats.json {};

      claudeTgCommand = let
        pluginId = "telegram@claude-plugins-official";

        # A question dialog would wait at a terminal nobody is watching
        askUserQuestionDenial = builtins.toJSON {
          hookSpecificOutput = {
            hookEventName = "PreToolUse";
            permissionDecision = "deny";
            permissionDecisionReason = "The user is away from the terminal and only reads Telegram. Ask through the telegram reply tool instead and wait for their answer.";
          };
        };

        sessionSettings = jsonFormat.generate "claude-tg-settings.json" {
          enabledPlugins.${pluginId} = true;
          hooks.PreToolUse = [
            {
              matcher = "AskUserQuestion";
              hooks = [
                {
                  type = "command";
                  command = "echo ${lib.escapeShellArg askUserQuestionDenial}";
                }
              ];
            }
          ];
        };
      in
        pkgs.writeShellApplication {
          name = "claude-tg";
          runtimeInputs = [
            config.programs.claude-code.finalPackage
            pkgs.bun
            pkgs.jq
          ];
          text = ''
            # Claude Code fetches no feature flags while telemetry is off, and channels sit behind one
            unset DO_NOT_TRACK

            if ! claude plugin list --json | jq -e 'any(.[]; .id == "${pluginId}")' >/dev/null; then
              claude plugin install telegram --marketplace anthropics/claude-plugins-official
              # Installing enables it in every session, where it would poll the bot away from this one
              claude plugin disable ${pluginId}
            fi

            exec claude --settings ${sessionSettings} --channels plugin:${pluginId} "$@"
          '';
        };
    in {
      age.secrets.claude-code-telegram-bot-token = {
        file = secrets."claude-code/telegram-bot-token";
        # Where the Telegram plugin reads its token
        path = "${config.programs.claude-code.configDir}/channels/telegram/.env";
      };

      home.packages = [claudeTgCommand];

      home.file."${config.programs.claude-code.configDir}/plugins/claude-hud/config.json".source = jsonFormat.generate "claude-hud-config.json" {
        language = "zh-Hans";
        lineLayout = "expanded";
        display = {
          showTools = true;
          showSkills = true;
          showMcp = true;
          showAgents = true;
          showTodos = true;

          showSessionName = true;
          showSessionTokens = true;
          showDuration = true;
          showCompactions = true;
          showEffortLevel = true;
          showOutputStyle = true;
          showAdvisor = true;

          showCost = true;
          showRoutedCost = true;
          showSpeed = true;
          showConfigCounts = true;

          showAuth = true;
          showClaudeCodeVersion = true;
          showMemoryUsage = true;
          showPromptCache = true;
        };
      };

      programs.claude-code = {
        enable = true;
        package = inputs.llm-agents.packages.${system}.claude-code;
        enableMcpIntegration = true;
        context = ''
          ${agentContext.rules}
          ${agentContext.codegraph}
        '';
        plugins = {inherit claude-code-wakatime claude-hud;};

        # claude-tg's plugin install writes settings.json, which a store symlink refuses
        mutableSettings = true;

        settings = {
          includeCoAuthoredBy = false;
          model = "opus[1m]";
          theme = "dark";
          outputStyle = "concise";
          tui = "fullscreen";

          hooks = config.programs.gryph.hooks.claude-code;

          # The persisted `effortLevel` only accepts low/medium/high/xhigh, so `max` has to come in through the env var; the `/model` picker ignores it and still shows the model default.
          env.CLAUDE_CODE_EFFORT_LEVEL = "max";

          permissions.defaultMode = "auto";

          statusLine = {
            type = "command";
            command = let
              claudeHudStatusline = pkgs.writeShellScript "claude-hud-statusline" ''
                cols=''${COLUMNS:-}
                case "$cols" in
                  ""|*[!0-9]*) cols=$(${pkgs.coreutils}/bin/stty size 2>/dev/null </dev/tty | ${pkgs.gawk}/bin/awk '{print $2}');;
                esac
                case "$cols" in
                  ""|*[!0-9]*) cols=120;;
                esac
                export COLUMNS=$(( cols > 4 ? cols - 4 : 1 ))
                exec ${lib.getExe claude-hud}
              '';
            in "${claudeHudStatusline}";
          };
        };
      };
    };
  };
}
