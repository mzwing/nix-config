# pi and its extensions. Skills come from software/skills, MCP and gryph from software/vibecoding.
{
  mzwing.features."software/pi-coding-agent" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    # The provider below points at that service.
    requires = ["software/cliproxyapiplus"];

    home = {
      config,
      inputs,
      lib,
      pkgs,
      secrets,
      ...
    }: let
      endpoint = import ../../../data/cliproxyapiplus.nix;

      jsonFormat = pkgs.formats.json {};

      # Keyed by plugin directory: each one reads <configDir>/extensions/<plugin>/config.json.
      piExtensionSettings = {
        pi-permission-auto-review = {
          "$schema" = "https://raw.githubusercontent.com/mzwing/pi-packages/main/packages/pi-permission-auto-review/schemas/config.schema.json";
          provider = "openai-codex";
          reasoning = "medium";
          additionalPolicy = "At any time, any execution that would result in `git commit` and `git push` operations is strictly prohibited! (Please note that this rule only prohibits these two operations. Read-only viewing is not included in this list and should be allowed in the correct context. `git add` can also be executed under reasonable circumstances)";
        };

        pi-permission-system = {
          debugLog = false;
          permissionReviewLog = true;
          yoloMode = false;
          authorizerChain = ["auto-review"];
        };

        pi-rtk-optimizer = {
          enabled = true;
          mode = "rewrite";
          guardWhenRtkMissing = true;
          showRewriteNotifications = true;
          outputCompaction = {
            enabled = true;
            stripAnsi = true;
            readCompaction.enabled = false;
            sourceCodeFilteringEnabled = false;
            preserveExactSkillReads = false;
            truncate = {
              enabled = true;
              maxChars = 12000;
            };
            sourceCodeFiltering = "none";
            smartTruncate = {
              enabled = false;
              maxLines = 220;
            };
            aggregateTestOutput = true;
            filterBuildOutput = true;
            compactGitOutput = true;
            aggregateLinterOutput = true;
            groupSearchOutput = true;
            trackSavings = true;
          };
        };
      };
    in {
      imports = [
        inputs.agenix.homeManagerModules.default
      ];

      # The same identity the system module uses, spelled again because Home Manager is a separate agenix instance — clients cannot read the service's copy of the secret.
      age.identityPaths = [
        "${config.home.homeDirectory}/.ssh/agenix"
      ];
      age.secrets."cliproxyapiplus-api-key".file = secrets."cliproxyapiplus/api-key";

      # No Home Manager option for plugin settings, so link the files. Editing them inside pi replaces the link, and the next activation backs that up as `config.json..bak` and relinks.
      home.file =
        lib.mapAttrs' (
          name: settings:
            lib.nameValuePair "${config.programs.pi-coding-agent.configDir}/extensions/${name}/config.json" {
              source = jsonFormat.generate "${name}-config.json" settings;
            }
        )
        piExtensionSettings;

      programs = {
        git.includes = [
          {
            # Internal snapshot commits must not inherit the user's signing policy.
            condition = "gitdir:${config.home.homeDirectory}/.pi/agent/state/workspace-history/";
            contents.commit.gpgSign = false;
          }
        ];
        pi-coding-agent = {
          enable = true;
          extraPackages = with pkgs; [
            git
            nodejs
            pnpm
            rtk
          ];
          context = "
            DO NOT use absolute paths when editing (except /tmp or /dev/null), since it will break the permission-system's auto review ability and fall back to let user decide. Use relative paths or workspace-relative paths instead.

            NEVER try to `git commit` or `git push`!

            NEVER try to rebuild the whole system!

            NEVER try to build any programs (especially Rust) locally, except the user explicitly approve it in the context. Ask the user to build it themselves instead.

            When possible, ALWAYS use the builtin tools (like read, edit, etc.) instead of shell commands! And when possible, ALWAYS use fffind / fffgrep instead of find / grep, since fffind / fffgrep is much faster and more efficient, but NOTICE: fffind / fffgrep is git-aware, and cannot search files not tracked by git.

            NEVER defensive programming! NEVER overthinking!

            <!-- CODEGRAPH_START -->
            ## CodeGraph

            In repositories indexed by CodeGraph (a `.codegraph/` directory exists at the repo root), reach for it BEFORE grep/find or reading files when you need to understand or locate code:

            - **MCP tool** (when available): `codegraph_explore` answers most code questions in one call — the relevant symbols' verbatim source plus the call paths between them, including dynamic-dispatch hops grep can't follow. Name a file or symbol in the query to read its current line-numbered source. If it's listed but deferred, load it by name via tool search.

            If there is no `.codegraph/` directory, skip CodeGraph entirely — indexing is the user's decision.
            <!-- CODEGRAPH_END -->
          ";
          models = {
            providers = {
              cliproxyapiplus = {
                api = "openai-completions";
                apiKey = "!cat ${config.age.secrets."cliproxyapiplus-api-key".path}";
                inherit (endpoint) baseUrl;
                authHeader = true;
                models = [];
              };
            };
          };
          settings = {
            defaultModel = "gpt-5.6-sol";
            defaultProvider = "openai-codex";
            defaultThinkingLevel = "xhigh";
            retry = {
              enabled = true;
              maxRetries = 3;
            };
            theme = "dark";
            npmCommand = [
              "pnpm"
              "--config.node-linker=hoisted"
            ];
            packages = [
              "npm:@ff-labs/pi-fff"
              "npm:@gotgenes/pi-permission-system"
              "npm:@gotgenes/pi-subagents"
              "npm:@gotgenes/pi-subagents-worktrees"
              "npm:@juicesharp/rpiv-ask-user-question"
              "npm:@mzwing/pi-permission-auto-review"
              "npm:@narumitw/pi-btw"
              "npm:@narumitw/pi-plan-mode"
              "npm:@narumitw/pi-usage"
              "npm:@upstash/context7-pi"
              "npm:pi-codex-goal"
              "npm:pi-effort"
              "npm:pi-markdown-preview"
              "npm:pi-mcp-adapter"
              "npm:pi-nano-context"
              "npm:pi-openai-api-models-sync"
              "npm:pi-provider-kimi-code"
              "npm:pi-rtk-optimizer"
              "npm:pi-simplify"
              "npm:pi-smart-fetch"
              "npm:pi-tool-display"
              "npm:pi-web-access"
              "npm:pi-workspace-history"
              "npm:pi-wtf"
            ];
          };
        };
      };
    };
  };
}
