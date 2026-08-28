# Claude Code, its statusline and the account switcher. Skills come from software/skills, MCP and gryph from software/vibecoding.
{
  mzwing.features."software/claude-code" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    darwin = {
      homebrew.casks = [
        "cc-switch"
      ];
    };

    nixos = {pkgs, ...}: {
      environment.systemPackages = with pkgs; [
        cc-switch
      ];
    };

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
        context = "
          NEVER try to git commit or push!

          NEVER try to rebuild the whole system!

          NEVER try to build any programs (especially Rust) locally, except the user explicitly approve it in the context. Ask the user to build it themselves instead.

          <!-- CODEGRAPH_START -->
          ## CodeGraph

          In repositories indexed by CodeGraph (a `.codegraph/` directory exists at the repo root), reach for it BEFORE grep/find or reading files when you need to understand or locate code:

          - **MCP tool** (when available): `codegraph_explore` answers most code questions in one call — the relevant symbols' verbatim source plus the call paths between them, including dynamic-dispatch hops grep can't follow. Name a file or symbol in the query to read its current line-numbered source. If it's listed but deferred, load it by name via tool search.

          If there is no `.codegraph/` directory, skip CodeGraph entirely — indexing is the user's decision.
          <!-- CODEGRAPH_END -->
        ";
        plugins.claude-hud = claude-hud;

        settings = {
          includeCoAuthoredBy = false;
          model = "opus";
          theme = "dark";

          # Flicker-free alt-screen renderer with virtualized scrollback; `/tui fullscreen` can't persist it since settings.json is a store symlink.
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
