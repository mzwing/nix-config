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
      jsonFormat = pkgs.formats.json {};
      yamlFormat = pkgs.formats.yaml {};
      proxyModel = id: "magpie/${id}";
      solModel = {
        model = proxyModel "gpt-6.1-sol";
        thinking_level = "high";
      };
      flashModel = {
        model = proxyModel "deepseek-flash";
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

        ".omp/agent/models.yml".source = yamlFormat.generate "omp-models.yml" {
          providers = lib.mapAttrs (name: gateway:
            {
              api = "openai-completions";
              # Loopback takes any key; this is the one magpie names omp's requests by.
              apiKey =
                if gateway.keyFile == null
                then "magpie-omp"
                else "!cat ${gateway.keyFile}";
              inherit (gateway) baseUrl;
              authHeader = true;
              # pi had a plugin sync its model list; omp asks the proxy itself.
              discovery.type = "openai-models-list";
            }
            // lib.optionalAttrs (name == "magpie") {
              # magpie serves codex-auto-review but leaves it out of its list. Without reasoning, pi-automode's effort would be dropped.
              models = [
                {
                  id = "codex/codex-auto-review";
                  reasoning = true;
                  compat.supportsReasoningEffort = true;
                }
              ];
              # Too new for omp's catalog; mirrors gpt-6-sol.
              modelOverrides."gpt-6.1-sol" = {
                reasoning = true;
                thinking = {
                  mode = "effort";
                  efforts = ["low" "medium" "high" "xhigh" "max"];
                };
                input = ["text" "image"];
                contextWindow = 1050000;
                maxTokens = 128000;
                compat.supportsReasoningEffort = true;
              };
            })
          config.mzwing.magpie.gateways;
        };

        # Reuse what programs.mcp already generated: omp's schema takes the same shape.
        ".omp/agent/mcp.json" = lib.mkIf (config.programs.mcp.servers != {}) {
          source = config.xdg.configFile."mcp/mcp.json".source;
        };

        # pi-automode reads its config from pi's directory even under omp.
        ".pi/agent/extensions/pi-automode/config.json".source = jsonFormat.generate "pi-automode-config.json" {
          autoMode = {
            classifierModel = proxyModel "codex/codex-auto-review";
            # The effort Codex itself reviews with.
            classifierReasoningLevel = "medium";
          };
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
          "@czottmann/pi-automode"
        ];
        settings = {
          # config.yml is reinstalled on every switch, so without this omp reruns its setup wizard each time.
          setupVersion = 2;

          # Magic Context owns compaction and automatic memory injection.
          compaction.enabled = false;
          memory.backend = "off";

          modelRoles = {
            default = proxyModel "claude-opus-5-5";
            slow = proxyModel "claude-opus-5-5:max";
            plan = proxyModel "claude-opus-5-5:max";
            task = proxyModel "claude-opus-5-5";
            smol = proxyModel "claude-opus-5-5:medium";
            commit = proxyModel "claude-opus-5-5:low";
            tiny = proxyModel "claude-opus-5-5:low";
          };
          defaultThinkingLevel = "xhigh";
          symbolPreset = "nerd";

          edit.mode = "apply_patch";

          retry = {
            enabled = true;
            maxRetries = 3;
            fallbackChains = {
              default = map proxyModel ["gpt-6.1-sol" "k3" "deepseek-flash"];
              smol = [(proxyModel "deepseek-flash:high")];
              commit = [(proxyModel "deepseek-flash:low")];
              tiny = [(proxyModel "deepseek-flash:low")];
            };
          };

          task = {
            agentModelOverrides.security-reviewer = map proxyModel ["k3:high" "deepseek-flash:max"];
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
