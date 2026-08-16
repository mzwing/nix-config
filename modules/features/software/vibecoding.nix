let
  cliproxyapiplusHost = "localhost";
  cliproxyapiplusPort = 8317;

  cliproxyapiplusService = {
    enable = true;
    settings = {
      host = cliproxyapiplusHost;
      port = cliproxyapiplusPort;

      debug = false;
      logging-to-file = true;
      logs-max-total-size-mb = 10;
      codex-instructions-enabled = false;

      remote-management = {
        allow-remote = false;
        disable-control-panel = false;
      };
    };
  };
in {
  mzwing.features."software/vibecoding" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    darwin = {
      config,
      inputs,
      username,
      ...
    }: {
      imports = [
        inputs.agenix.darwinModules.default
        inputs.nur.repos.mzwing.modules.darwin.cliproxyapiplus
      ];

      # The age recipients match the Home Manager deployment, so the same
      # user key decrypts them at the system level (as root).
      age.identityPaths = ["${config.users.users.${username}.home}/.ssh/server_key"];
      age.secrets = {
        cliproxyapiplus-api-key = {
          file = ../../../secrets/cliproxyapiplus/api-key.age;
          owner = "_cliproxyapiplus";
          group = "_cliproxyapiplus";
        };
        cliproxyapiplus-remote-secret-key = {
          file = ../../../secrets/cliproxyapiplus/remote-secret-key.age;
          owner = "_cliproxyapiplus";
          group = "_cliproxyapiplus";
        };
      };

      services.cliproxyapiplus =
        cliproxyapiplusService
        // {
          apiKeysPaths = [config.age.secrets.cliproxyapiplus-api-key.path];
          remoteSecretKeyPath = config.age.secrets.cliproxyapiplus-remote-secret-key.path;
        };

      homebrew.casks = [
        "antigravity"
        "cc-switch"
        "chatgpt"
      ];
    };

    nixos = {
      config,
      inputs,
      pkgs,
      username,
      ...
    }: {
      imports = [
        inputs.nur.repos.mzwing.modules.nixos.cliproxyapiplus
      ];

      age.identityPaths = ["${config.users.users.${username}.home}/.ssh/server_key"];
      age.secrets = {
        cliproxyapiplus-api-key = {
          file = ../../../secrets/cliproxyapiplus/api-key.age;
          owner = "cliproxyapiplus";
          group = "cliproxyapiplus";
        };
        cliproxyapiplus-remote-secret-key = {
          file = ../../../secrets/cliproxyapiplus/remote-secret-key.age;
          owner = "cliproxyapiplus";
          group = "cliproxyapiplus";
        };
      };

      services.cliproxyapiplus =
        cliproxyapiplusService
        // {
          apiKeysPaths = [config.age.secrets.cliproxyapiplus-api-key.path];
          remoteSecretKeyPath = config.age.secrets.cliproxyapiplus-remote-secret-key.path;
        };

      environment.systemPackages = with pkgs; [
        antigravity
        cc-switch
      ];
    };

    home = {
      config,
      inputs,
      lib,
      pkgs,
      ...
    }: let
      claudeHudSrc = pkgs.fetchFromGitHub {
        owner = "jarrodwatts";
        repo = "claude-hud";
        rev = "v0.7.1";
        hash = "sha256-LvSuIbniF4lC2ruopijAo9avGAWjNS2YLa/EiFW0IBU=";
      };
    in {
      imports = [
        inputs.agenix.homeManagerModules.default
        inputs.nur.repos.mzwing.modules.homeManager.gryph
      ];

      age.identityPaths = [
        "${config.home.homeDirectory}/.ssh/server_key"
      ];
      age.secrets."cliproxyapiplus-api-key".file = ../../../secrets/cliproxyapiplus/api-key.age;

      home.packages = [
        pkgs.nur.repos.mzwing.codegraph
      ];

      home.file."${config.programs.claude-code.configDir}/plugins/claude-hud/config.json".source = (pkgs.formats.json {}).generate "claude-hud-config.json" {
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

      programs = {
        claude-code = {
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
          plugins.claude-hud = claudeHudSrc;

          settings = {
            includeCoAuthoredBy = false;
            theme = "dark";
            hooks = config.programs.gryph.hooks.claude-code;

            env = {
              "ENABLE_PROMPT_CACHING_1H" = "1";
            };

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
                  exec ${lib.getExe pkgs.nodejs} ${claudeHudSrc}/dist/index.js
                '';
              in "${claudeHudStatusline}";
            };
          };
        };
        mcp = {
          enable = true;
          servers = {
            # ace-ctx = {
            #   command = lib.getExe pkgs.nur.repos.mzwing.ace-ctx;
            #   env = {
            #     ACE_BASE_URL = "http://localhost:8999";
            #     ACE_TOKEN = "sk-1145141919810";
            #   };
            # };
            codegraph = {
              command = lib.getExe pkgs.nur.repos.mzwing.codegraph;
              args = [
                "serve"
                "--mcp"
              ];
              env = {
                CODEGRAPH_TELEMETRY = "0";
                CODEGRAPH_NO_UPDATE_CHECK = "1";
              };
            };
          };
        };
        gryph = {
          enable = true;
          enableIntegration.pi-agent = true;
          settings.storage.retention_days = 30;
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
          extraPackages = with pkgs; [
            git
            nodejs
            pnpm
            rtk
          ];
          context = "
            DO NOT use absolute paths when editing (except /tmp or /dev/null), since it will break the permission-system's auto review ability and fall back to let user decide. Use relative paths or workspace-relative paths instead.

            NEVER try to git commit or push!

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
                baseUrl = "http://${cliproxyapiplusHost}:${toString cliproxyapiplusPort}/v1";
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
              "npm:tau-mirror"
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
