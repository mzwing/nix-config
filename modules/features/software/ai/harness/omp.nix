let
  agentContext = import ../../../../../data/agent-context.nix;

  ompPlugins = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.programs.omp;
  in {
    options.programs.omp.plugins = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "npm plugins installed and upgraded on every activation; any other npm plugin gets uninstalled.";
    };

    config = lib.mkIf cfg.enable {
      home.activation.ompPlugins = lib.hm.dag.entryAfter ["linkGeneration"] ''
        (
          # omp shells out to bun for plugin installs.
          export PATH=${lib.makeBinPath [cfg.package pkgs.bun]}:$PATH
          for plugin in $(omp plugin list --json | jq -r --argjson declared ${lib.escapeShellArg (builtins.toJSON cfg.plugins)} '.npm[].name | select(IN($declared[]) | not)'); do
            run omp plugin uninstall "$plugin"
          done
          # Reinstalling is how omp upgrades an npm plugin.
          ${lib.optionalString (cfg.plugins != []) ''run omp plugin install ${lib.escapeShellArgs cfg.plugins} || warnEcho "omp plugin install failed; the next activation retries it."''}
        )
      '';
    };
  };
in {
  mzwing.features."software/ai/harness/omp" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    requires = [
      "software/vcs/git"
      "software/ai/magpie-client"
    ];

    home = {
      config,
      inputs,
      lib,
      pkgs,
      system,
      ...
    }: let
      yamlFormat = pkgs.formats.yaml {};
      inherit (config.mzwing.magpie) gateway;
      proxyModel = id: "magpie/${id}";
      taskModel = proxyModel "auto/gpt-6.1-terra:xhigh";
      solModel = {
        model = proxyModel "auto/gpt-6.1-sol";
        thinking_level = "high";
      };
      flashModel = {
        model = proxyModel "auto/deepseek-v4.1-flash";
        thinking_level = "high";
      };
    in {
      imports = [
        inputs.nur.repos.mzwing.modules.homeManager.magic-context
        inputs.oh-my-pi.homeManagerModules.default
        ompPlugins
      ];

      # Only config.yml is rewritten at runtime, and programs.omp installs that one as a writable copy. The rest can be store symlinks.
      home.file = {
        ".omp/agent/AGENTS.md".text = ''
          ${agentContext.rules}

          When possible, ALWAYS use the builtin tools (like read, edit, etc.) instead of shell commands!

          NEVER overthinking!

          ${agentContext.codegraph}
        '';

        # Subagents never receive AGENTS.md
        ".omp/agent/rules/conventions.md".text = ''
          ---
          alwaysApply: true
          agents: [task, sonic, expert, docs-writer]
          ---

          ${agentContext.rules}
        '';
        ".omp/agent/rules/director.md".text = builtins.replaceStrings ["@taskModel@"] [taskModel] (builtins.readFile ../../../../../data/omp/rules/director.md);
        ".omp/agent/rules/worker.md".source = ../../../../../data/omp/rules/worker.md;
        ".omp/agent/agents" = {
          source = ../../../../../data/omp/agents;
          recursive = true;
        };

        ".omp/agent/models.yml".source = yamlFormat.generate "omp-models.yml" {
          providers.magpie = {
            api = "openai-completions";
            # Loopback takes any key; this is the one magpie names omp's requests by.
            apiKey =
              if gateway.keyFile == null
              then "magpie-omp"
              else "!cat ${gateway.keyFile}";
            inherit (gateway) baseUrl;
            authHeader = true;
            # pi had a plugin sync its model list; omp asks the proxy itself.
            discovery = {
              type = "openai-models-list";
              # A fresh omp on CNB can miss the 10 s default: the list crawls in from azure while omp refreshes its built-in catalogs
              timeoutMs = 60000;
            };
          };
        };

        # Reuse what programs.mcp already generated: omp's schema takes the same shape.
        ".omp/agent/mcp.json" = lib.mkIf (config.programs.mcp.servers != {}) {
          source = config.xdg.configFile."mcp/mcp.json".source;
        };
      };

      programs.magic-context = {
        enable = true;
        settings = {
          historian.omp = {
            model = solModel;
            fallback_models = [flashModel];
          };
          dreamer.omp = {
            model = flashModel;
            fallback_models = [solModel];
            tasks = lib.genAttrs ["curate" "retrospective" "review-user-memories"] (_: {
              model = solModel;
              fallback_models = [flashModel];
            });
          };
        };
      };

      programs.omp = {
        enable = true;
        package = inputs.llm-agents.packages.${system}.omp;
        plugins = [
          "@cortexkit/pi-magic-context"
        ];
        settings = {
          # config.yml is reinstalled on every switch, so without this omp reruns its setup wizard each time.
          setupVersion = 2;

          # Magic Context owns compaction and automatic memory injection.
          compaction.enabled = false;
          memory.backend = "off";

          modelRoles = {
            default = proxyModel "auto/claude-opus-5-5:max";
            slow = proxyModel "auto/claude-opus-5-5:max";
            plan = proxyModel "auto/claude-opus-5-5:max";
            task = taskModel;
            smol = taskModel;
            docs = proxyModel "auto/gemini-4-argon";
            commit = proxyModel "auto/claude-opus-5-5:low";
            tiny = proxyModel "auto/claude-opus-5-5:low";
          };
          defaultThinkingLevel = "xhigh";
          symbolPreset = "nerd";

          edit.mode = "apply_patch";

          retry = {
            enabled = true;
            maxRetries = 3;
            fallbackChains = {
              default = map proxyModel ["auto/gpt-6.1-sol" "auto/deepseek-v4.1-flash"];
              smol = [(proxyModel "auto/claude-sonnet-5-5:xhigh")];
              commit = [(proxyModel "auto/deepseek-v4.1-flash:low")];
              tiny = [(proxyModel "auto/deepseek-v4.1-flash:low")];
            };
          };

          task = {
            agentModelOverrides.security-reviewer = [(proxyModel "auto/deepseek-v4.1-flash:max")];
            perCallModel = "on";
            showResolvedModelBadge = true;
          };

          tools.approvalMode = "yolo";

          # Not `git commit *`: that demands an argument, and a bare `git commit` would open $EDITOR and slip past.
          bash.patterns = [
            {
              match = "git commit*";
              approval = "deny";
            }
            {
              match = "git push*";
              approval = "deny";
            }
          ];
        };
      };
    };
  };
}
