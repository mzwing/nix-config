let
  agentContext = import ../../../../../data/agent-context.nix;
in {
  mzwing.features."software/ai/harness/pi-coding-agent" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    requires = [
      "darwin/homebrew"
      "software/vcs/git"
      "software/ai/harness/gryph"
      "software/ai/magpie-client"
      "software/development/wakatime"
    ];

    darwin.homebrew.casks = [
      "magic-context-dashboard"
    ];

    home = {
      config,
      inputs,
      lib,
      pkgs,
      system,
      ...
    }: let
      jsonFormat = pkgs.formats.json {};
      solModel = {
        model = "magpie/gpt-6.1-sol";
        thinking_level = "high";
      };
      flashModel = {
        model = "magpie/deepseek-flash";
        thinking_level = "high";
      };

      # Keyed by plugin directory: each one reads <configDir>/extensions/<plugin>/config.json.
      piExtensionSettings = {
        pi-model-info = {
          "$schema" = "https://raw.githubusercontent.com/mzwing/pi-packages/main/packages/pi-model-info/schemas/config.schema.json";
          providers.magpie = {};
        };

        pi-permission-auto-review = {
          "$schema" = "https://raw.githubusercontent.com/mzwing/pi-packages/main/packages/pi-permission-auto-review/schemas/config.schema.json";
          provider = "magpie";
          # magpie answers the bare id with a 404.
          model = "codex/codex-auto-review";
          reasoning = "medium";
          additionalPolicy = "At any time, any execution that would result in `git commit` and `git push` operations is strictly prohibited! The only exception is committing in a pi-task-governor coordinator session, recognizable by its `task_*` tool calls and task notices; pushing stays prohibited there too. (Please note that this rule only prohibits these two operations. Read-only viewing is not included in this list and should be allowed in the correct context. `git add` can also be executed under reasonable circumstances)";
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
            coordinator.instructions = "Never rebuild the whole system, and never ask a task to. A Rust project is built only with the user's explicit authorization: put a check or instruction that compiles Rust code into a brief only after the user authorizes it for that task, and then say in the brief that the user authorized it. In other projects, tasks may run checks, tests and builds on their own. Write every commit message, the ones you give task_approve included, with the conventional-commit-message and semver skills. You may commit wherever it is reasonable, which overrides the general rule for `git commit` only: never push with `git push`, `jj git push` or anything else that sends commits, bookmarks or tags to a remote.";
            executor = {
              model = "magpie/deepseek-flash";
              thinking = "max";
              instructions = "In a Rust project, never ask the developer to compile Rust code unless the brief says the user explicitly authorized it through the coordinator.";
            };
            developer = {
              model = "magpie/kimi-k3";
              thinking = "max";
              instructions = "Never rebuild the whole system. In a Rust project, never compile Rust code, whether with cargo build, check, clippy, test, run or anything like them, unless the brief says the user explicitly authorized it through the coordinator. In other projects, run checks, tests and builds on your own. These rules override the general rule on building.";
            };
            reviewer = {
              model = "magpie/gpt-6.1-sol";
              thinking = "xhigh";
              instructions = "NEVER try to write so many meaningless smoke tests!!!!!";
            };
          };
        };
      };
    in {
      imports = [
        inputs.nur.repos.mzwing.modules.homeManager.magic-context
      ];

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
            pnpm-bin.latest
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
            providers =
              lib.mapAttrs (_: gateway: {
                api = "openai-completions";
                # Loopback takes any key; this is the one magpie names pi's requests by.
                apiKey =
                  if gateway.keyFile == null
                  then "magpie-pi"
                  else "!cat ${gateway.keyFile}";
                inherit (gateway) baseUrl;
                authHeader = true;
                models = [];
              })
              config.mzwing.magpie.gateways
              // {
                openai-codex.modelOverrides."gpt-5.6-sol".contextWindow = 1050000;
              };
          };
          settings = {
            defaultModel = "deepseek-v4-pro";
            defaultProvider = "magpie";
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
