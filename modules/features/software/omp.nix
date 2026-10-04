let
  agentContext = import ../../../data/agent-context.nix;
  endpoint = import ../../../data/cliproxyapiplus.nix;

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
  mzwing.features."software/omp" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    requires = [
      "software/cliproxyapiplus"
      "software/git"
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
      yamlFormat = pkgs.formats.yaml {};
      proxyModel = id: "cliproxyapiplus/${id}";
    in {
      imports = [
        inputs.agenix.homeManagerModules.default
        inputs.nur.repos.mzwing.modules.homeManager.magic-context
        inputs.oh-my-pi.homeManagerModules.default
        ompPlugins
      ];

      # Home Manager is a separate agenix instance, so it cannot read the service's copy of the secret.
      age.identityPaths = [
        "${config.home.homeDirectory}/.ssh/agenix"
      ];
      age.secrets."cliproxyapiplus-api-key".file = secrets."cliproxyapiplus/api-key";

      # Only config.yml is rewritten at runtime, and programs.omp installs that one as a writable copy. The rest can be store symlinks.
      home.file = {
        ".omp/agent/AGENTS.md".text = ''
          ${agentContext.rules}

          When possible, ALWAYS use the builtin tools (like read, edit, etc.) instead of shell commands!

          NEVER overthinking!

          ${agentContext.codegraph}
        '';

        ".omp/agent/models.yml".source = yamlFormat.generate "omp-models.yml" {
          providers.cliproxyapiplus = {
            api = "openai-completions";
            apiKey = "!cat ${config.age.secrets."cliproxyapiplus-api-key".path}";
            inherit (endpoint) baseUrl;
            authHeader = true;
            # pi had a plugin sync its model list; omp asks the proxy itself.
            discovery.type = "openai-models-list";
            # omp's catalog has no entry for codex-auto-review, so it would otherwise drop pi-automode's reasoning effort.
            modelOverrides = {
              codex-auto-review = {
                reasoning = true;
                compat.supportsReasoningEffort = true;
              };
            };
          };
        };

        # Reuse what programs.mcp already generated: omp's schema takes the same shape.
        ".omp/agent/mcp.json" = lib.mkIf (config.programs.mcp.servers != {}) {
          source = config.xdg.configFile."mcp/mcp.json".source;
        };

        # pi-automode reads its config from pi's directory even under omp.
        ".pi/agent/extensions/pi-automode/config.json".source = jsonFormat.generate "pi-automode-config.json" {
          autoMode = {
            classifierModel = proxyModel "codex-auto-review";
            # The effort Codex itself reviews with.
            classifierReasoningLevel = "medium";
          };
        };
      };

      programs.magic-context = {
        enable = true;
        settings = {
          historian.omp = {
            model = {
              model = proxyModel "gpt-6.1-sol";
              thinking_level = "xhigh";
            };
            fallback_models = [(proxyModel "deepseek-flash")];
          };
          dreamer.omp.model = {
            model = proxyModel "gpt-6.1-sol";
            thinking_level = "xhigh";
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
            default = proxyModel "gpt-6.1-sol";
            slow = proxyModel "gpt-6.1-sol:max";
            plan = proxyModel "gpt-6.1-sol:max";
            task = proxyModel "gpt-6.1-sol";
            smol = proxyModel "gpt-6.1-sol:medium";
            commit = proxyModel "gpt-6.1-sol:low";
            tiny = proxyModel "gpt-6.1-sol:low";
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
