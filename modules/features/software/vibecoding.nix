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
        ];
      };
    };

    nixos = {pkgs, ...}: {
      environment.systemPackages = with pkgs; [
        antigravity
      ];
    };

    home = {
      lib,
      pkgs,
      ...
    }: {
      programs = {
        antigravity-cli = {
          enable = true;
          enableMcpIntegration = true;
        };
        pi-coding-agent = {
          enable = true;
          extraPackages = with pkgs; [
            git
            nodejs
            pnpm
          ];
          settings = {
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
              "npm:@narumitw/pi-plan-mode"
              "npm:@upstash/context7-pi"
              "npm:pi-codex-goal"
              "npm:pi-markdown-preview"
              "npm:pi-mcp-adapter"
              "npm:pi-nano-context"
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
