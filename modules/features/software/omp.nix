let
  agentContext = import ../../../data/agent-context.nix;
  endpoint = import ../../../data/cliproxyapiplus.nix;
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
      yamlFormat = pkgs.formats.yaml {};
    in {
      imports = [
        inputs.agenix.homeManagerModules.default
        inputs.oh-my-pi.homeManagerModules.default
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

          NEVER defensive programming! NEVER overthinking!

          ${agentContext.codegraph}
        '';

        ".omp/agent/models.yml".source = yamlFormat.generate "omp-models.yml" {
          providers = {
            cliproxyapiplus = {
              api = "openai-completions";
              apiKey = "!cat ${config.age.secrets."cliproxyapiplus-api-key".path}";
              inherit (endpoint) baseUrl;
              authHeader = true;
              # pi had a plugin sync its model list; omp asks the proxy itself.
              discovery.type = "openai-models-list";
            };

            openai-codex.modelOverrides."gpt-5.6-sol".contextWindow = 1050000;
          };
        };

        # Reuse what programs.mcp already generated: omp's schema takes the same shape.
        ".omp/agent/mcp.json" = lib.mkIf (config.programs.mcp.servers != {}) {
          source = config.xdg.configFile."mcp/mcp.json".source;
        };
      };

      programs.omp = {
        enable = true;
        package = inputs.llm-agents.packages.${system}.omp;
        settings = {
          modelRoles.default = "openai-codex/gpt-6-astra";
          defaultThinkingLevel = "xhigh";
          symbolPreset = "nerd";

          retry = {
            enabled = true;
            maxRetries = 3;
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
