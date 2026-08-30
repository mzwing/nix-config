let
  agentContext = import ../../../data/agent-context.nix;
in {
  mzwing.features."software/claude-code" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    requires = [
      "darwin/homebrew"
      # `hooks` below reads programs.gryph.
      "software/gryph"
    ];

    packages.nixos = pkgs: [pkgs.cc-switch];

    darwin.homebrew.casks = [
      "cc-switch"
    ];

    home = {
      config,
      lib,
      pkgs,
      ...
    }: let
      claude-hud = pkgs.nur.repos.mzwing.claude-hud;

      jsonFormat = pkgs.formats.json {};
    in {
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
          promptCacheTtlSeconds = 3600; # The fxxking cc hud hardcodes cache TTL to 5 mins, so we have to set it to 1 hour for Claude Coding Plan manually.
        };
      };

      programs.claude-code = {
        enable = true;
        enableMcpIntegration = true;
        context = ''
          NEVER try to git commit or push!

          ${agentContext.rules}
          ${agentContext.codegraph}
        '';
        plugins.claude-hud = claude-hud;

        settings = {
          includeCoAuthoredBy = false;
          model = "opus";
          theme = "dark";

          # `/tui fullscreen` cannot persist this: settings.json is a store symlink.
          tui = "fullscreen";

          hooks = config.programs.gryph.hooks.claude-code;

          # The persisted `effortLevel` only accepts low/medium/high/xhigh, so `max` has to come in through the env var.
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
