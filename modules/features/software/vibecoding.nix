{
  mzwing.features."software/vibecoding" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    darwin = {
      homebrew = {
        brews = [
          "cliproxyapiplus"
          "gryph"
        ];
        casks = [
          "antigravity"
          "chatgpt"
        ];
      };
    };

    nixos = {pkgs, ...}: {
      environment.systemPackages = with pkgs; [
        antigravity
      ];
    };

    home = {
      config,
      inputs,
      lib,
      pkgs,
      ...
    }: {
      imports = [inputs.agenix.homeManagerModules.default];

      age.identityPaths = [
        "${config.home.homeDirectory}/.ssh/server_key"
      ];
      age.secrets."cliproxyapiplus-api-key".file = "${inputs.self}/secrets/cliproxyapiplus/api-key.age";

      programs = {
        antigravity-cli = {
          enable = true;
          enableMcpIntegration = true;
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
          ];
          models = {
            providers = {
              cliproxyapiplus = {
                api = "openai-completions";
                apiKey = "!cat ${config.age.secrets."cliproxyapiplus-api-key".path}";
                baseUrl = "http://localhost:8317/v1";
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
              "git:github.com/justhil/pi-ace-tool"
              "git:github.com/justhil/pi-fast-context"
              "npm:@complexthings/pi-dynamic-context-pruning"
              "npm:@ff-labs/pi-fff"
              "npm:@gotgenes/pi-permission-system"
              "npm:@gotgenes/pi-subagents"
              "npm:@gotgenes/pi-subagents-worktrees"
              "npm:@juicesharp/rpiv-ask-user-question"
              "npm:@narumitw/pi-btw"
              "npm:@upstash/context7-pi"
              "npm:pi-codex-goal"
              "npm:pi-effort"
              "npm:pi-markdown-preview"
              "npm:pi-mcp-adapter"
              "npm:pi-nano-context"
              "npm:pi-openai-api-models-sync"
              "npm:pi-plan"
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
