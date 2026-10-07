let
  agentContext = import ../../../data/agent-context.nix;
  endpoint = import ../../../data/cliproxyapiplus.nix;
in {
  mzwing.features."software/pi-coding-agent" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    requires = [
      "darwin/homebrew"
      "software/cliproxyapiplus"
      "software/git"
      "software/gryph"
      "software/wakatime"
    ];

    darwin.homebrew.casks = [
      "magic-context-dashboard"
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
      jsonFormat = pkgs.formats.json {};
      solModel = {
        model = "cliproxyapiplus/gpt-6.1-sol";
        thinking_level = "high";
      };
      flashModel = {
        model = "cliproxyapiplus/deepseek-flash";
        thinking_level = "high";
      };

      # Keyed by plugin directory: each one reads <configDir>/extensions/<plugin>/config.json.
      piExtensionSettings = {
        pi-model-info = {
          "$schema" = "https://raw.githubusercontent.com/mzwing/pi-packages/main/packages/pi-model-info/schemas/config.schema.json";
          providers.cliproxyapiplus = {};
        };

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
          promptNotifications = ["osc777"];
          # Read-only and pi-task-governor tools skip auto-review. pi-permission-system never lets auto-review approve access outside the working directory, so reads there are allowed outright, as is everything under /tmp (/private/tmp on macOS), and other writes there still ask you.
          permission = {
            "*" = "ask";
            external_directory = {
              "*" = "ask";
              "/tmp/*" = "allow";
              "/private/tmp/*" = "allow";
            };
            external_directory_read = "allow";
            read = "allow";
            grep = "allow";
            find = "allow";
            ls = "allow";
            "task_*" = "allow";
            session_list = "allow";
            session_read = "allow";
          };
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

        pi-task-governor = {
          "$schema" = "https://raw.githubusercontent.com/mzwing/pi-packages/master/packages/pi-task-governor/schemas/config.schema.json";
          roles = {
            coordinator.instructions = "Never rebuild the whole system, and never ask a task to. A Rust project is built only with the user's explicit authorization: put a check or instruction that compiles Rust code into a brief only after the user authorizes it for that task, and then say in the brief that the user authorized it. In other projects, tasks may run checks, tests and builds on their own.";
            executor = {
              model = "cliproxyapiplus/deepseek-flash";
              thinking = "max";
              instructions = "In a Rust project, never ask the developer to compile Rust code unless the brief says the user explicitly authorized it through the coordinator.";
            };
            developer = {
              model = "cliproxyapiplus/claude-opus-5-5";
              thinking = "max";
              instructions = "Never rebuild the whole system. In a Rust project, never compile Rust code, whether with cargo build, check, clippy, test, run or anything like them, unless the brief says the user explicitly authorized it through the coordinator. In other projects, run checks, tests and builds on your own. These rules override the general rule on building.";
            };
            reviewer = {
              model = "cliproxyapiplus/gpt-6.1-sol";
              thinking = "xhigh";
            };
          };
        };
      };
    in {
      imports = [
        inputs.agenix.homeManagerModules.default
        inputs.nur.repos.mzwing.modules.homeManager.magic-context
      ];

      # Home Manager is a separate agenix instance, so it cannot read the service's copy of the secret.
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
        piExtensionSettings
        // {
          # pi's default exposure hides MCP tools behind codemode; codegraph is meant to be called first.
          "${config.programs.pi-coding-agent.configDir}/mcp.json".source = jsonFormat.generate "pi-mcp.json" {
            mcpServers = lib.mapAttrs (_: server: lib.hm.mcp.transformMcpServer {inherit server;} // {exposure = "direct";}) config.programs.mcp.servers;
          };
        };

      programs = {
        gryph.enableIntegration.pi-agent = true;

        magic-context = {
          enable = true;
          settings = {
            historian.pi = {
              model = solModel;
              fallback_models = [flashModel];
            };
            dreamer.pi = {
              model = flashModel;
              fallback_models = [solModel];
              tasks = lib.genAttrs ["curate" "retrospective" "review-user-memories"] (_: {
                model = solModel;
                fallback_models = [flashModel];
              });
            };
          };
        };

        git.includes = [
          {
            # Internal snapshot commits must not inherit the user's signing policy.
            condition = "gitdir:${config.home.homeDirectory}/.pi/agent/state/workspace-history/";
            contents.commit.gpgSign = false;
          }
        ];
        pi-coding-agent = {
          enable = true;
          package = inputs.llm-agents.packages.${system}.pi;
          extraPackages = with pkgs; [
            git
            nodejs
            pnpm
            rtk
            wakatime-cli
          ];
          context = ''
            DO NOT use absolute paths when editing (except /tmp or /dev/null), since it will break the permission-system's auto review ability and fall back to let user decide. Use relative paths or workspace-relative paths instead.

            ${agentContext.rules}

            When possible, ALWAYS use the builtin tools (like read, edit, etc.) instead of shell commands! And when possible, ALWAYS use fffind / ffgrep instead of find / grep, since fffind / ffgrep is much faster and more efficient, but NOTICE: fffind / ffgrep is git-aware, and cannot search files not tracked by git.

            NEVER overthinking!

            ${agentContext.codegraph}
          '';
          models = {
            providers = {
              cliproxyapiplus = {
                api = "openai-completions";
                apiKey = "!cat ${config.age.secrets."cliproxyapiplus-api-key".path}";
                inherit (endpoint) baseUrl;
                authHeader = true;
                models = [];
              };

              openai-codex.modelOverrides."gpt-5.6-sol".contextWindow = 1050000;
            };
          };
          settings = {
            defaultModel = "claude-opus-5-5";
            defaultProvider = "cliproxyapiplus";
            defaultThinkingLevel = "max";
            defaultTools = ["+ls"];
            retry = {
              enabled = true;
              maxRetries = 3;
            };
            tuiMode = "fullscreen";
            npmCommand = [
              "pnpm"
              "--config.node-linker=hoisted"
            ];
            packages = [
              "npm:@cortexkit/pi-magic-context"
              "npm:@ff-labs/pi-fff"
              "npm:@gotgenes/pi-permission-system"
              "npm:@gotgenes/pi-subagents"
              "npm:@gotgenes/pi-subagents-worktrees"
              "npm:@mzwing/pi-codex-downgrade-detector"
              "npm:@mzwing/pi-model-info"
              "npm:@mzwing/pi-permission-auto-review"
              "npm:@mzwing/pi-session-hub"
              "npm:@mzwing/pi-task-governor"
              "npm:@narumitw/pi-btw"
              "npm:@narumitw/pi-plan-mode"
              "npm:@narumitw/pi-usage"
              "npm:@pi-lab/notify"
              "npm:@tylerho/pi-ask-user-question"
              "npm:@upstash/context7-pi"
              "npm:pi-codex-goal"
              "npm:pi-markdown-preview"
              "npm:pi-nano-context"
              "npm:pi-openai-api-models-sync"
              "npm:pi-rtk-optimizer"
              "npm:pi-simplify"
              "npm:pi-smart-fetch"
              "npm:pi-wakatime"
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
