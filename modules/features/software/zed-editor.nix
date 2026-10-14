let
  endpoint = import ../../../data/magpie.nix;
in {
  mzwing.features."software/zed-editor" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    requires = [
      "software/magpie"
      # The wakatime extension only tracks once ~/.wakatime.cfg carries the key.
      "software/wakatime"
    ];

    home = {
      lib,
      pkgs,
      ...
    }: let
      typenix = lib.getExe pkgs.nur.repos.mzwing.typenix;

      # typescript-ls is tsgo, standing in for vtsls as useTsgo does in VSCode.
      typescriptServers = ["typescript-ls" "!vtsls" "!typescript-language-server" "..."];

      magpieModel = lib.recursiveUpdate {
        reasoning_effort = "high";
        capabilities = {
          tools = true;
          images = true;
          parallel_tool_calls = false;
          prompt_cache_key = false;
          # Otherwise Zed replays earlier reasoning as plain reply text.
          interleaved_reasoning = true;
        };
      };
    in {
      # Zed reads MAGPIE_API_KEY once at startup, before the login shell's environment arrives, so the session manager has to carry it. Loopback takes any key; this one names Zed's requests in magpie.
      launchd.agents.zed-magpie-api-key = {
        enable = true;
        config = {
          ProgramArguments = ["/bin/launchctl" "setenv" "MAGPIE_API_KEY" "magpie-zed"];
          RunAtLoad = true;
        };
      };
      systemd.user.sessionVariables.MAGPIE_API_KEY = "magpie-zed";

      programs.zed-editor = {
        enable = true;
        extensions = [
          "bookmark"
          "caddyfile"
          "dart"
          "deno"
          "desktop"
          "docker-compose"
          "editorconfig"
          "emmet"
          "env"
          "fish"
          "flutter-snippets"
          "git-firefly"
          "github-actions"
          "github-actions-snippets"
          "go-snippets"
          "gosum"
          "graphql"
          "java"
          "javascript-snippets"
          "jsonl"
          "just"
          "kotlin"
          "make"
          "markdown-snippets"
          "markdownlint"
          "mcp-server-context7"
          "neocmake"
          "nix"
          "oxc"
          "powershell"
          "python-autodoc-lsp"
          "python-snippets"
          "rainbow-csv"
          "rlsp-yaml"
          "ruby"
          "seti-icons"
          "solid-typescript-snippets"
          "svelte"
          "swift"
          "todo-highlight-language-server"
          "toml"
          "tsgo"
          "typescript-snippets"
          "typst"
          "vscode-dark-modern"
          "vue"
          "wakatime"
          "xml"
          "zig"
        ];
        userSettings = {
          base_keymap = "VSCode";
          theme = "VSCode Dark Modern";
          icon_theme = "Seti Icon Theme";

          ui_font_family = "JetBrainsMono Nerd Font";
          buffer_font_family = "JetBrainsMono Nerd Font";
          buffer_font_size = 13;

          tab_size = 2;
          soft_wrap = "editor_width";
          autosave = "on_focus_change";
          minimap.show = "always";
          indent_guides.background_coloring = "indent_aware";
          diagnostics.inline.enabled = true;
          use_smartcase_search = true;
          search = {
            center_on_match = true;
            include_ignored = true;
          };
          status_bar.active_encoding_button = "enabled";

          project_panel.dock = "left";
          git_panel.dock = "left";
          agent = {
            dock = "right";
            default_model = {
              provider = "magpie";
              model = "claude-opus-5-5";
              enable_thinking = true;
            };
          };

          language_models.openai_compatible.magpie = {
            api_url = endpoint.baseUrl;
            # Zed cannot list this provider's models itself; the specs are copied from magpie's /v1/models.
            available_models = map magpieModel [
              {
                name = "claude-opus-5-5";
                max_tokens = 1000000;
                max_output_tokens = 128000;
              }
              {
                name = "gpt-6.1-sol";
                max_tokens = 500000;
                max_output_tokens = 128000;
              }
              {
                name = "deepseek-v4-pro";
                max_tokens = 1000000;
                max_output_tokens = 393216;
                capabilities.images = false;
              }
              {
                name = "deepseek-flash";
                max_tokens = 1000000;
                max_output_tokens = 393216;
              }
              {
                name = "k3";
                max_tokens = 1048576;
                max_output_tokens = 131072;
              }
            ];
          };

          telemetry = {
            diagnostics = false;
            metrics = false;
          };

          # Not extraPackages: macOS starts Zed.app directly, past the PATH wrapper, so tools go in by store path.
          # Zed has no typenix extension, so it runs in the nix extension's nil slot.
          lsp.nil.binary = {
            path = typenix;
            arguments = ["--lsp" "--stdio"];
          };
          prettier.allowed = true;
          languages = {
            Nix = {
              language_servers = ["nil" "!nixd" "..."];
              formatter.external = {
                command = lib.getExe pkgs.alejandra;
                arguments = ["--quiet"];
              };
            };
            JavaScript.language_servers = typescriptServers;
            TypeScript.language_servers = typescriptServers;
            TSX.language_servers = typescriptServers;
          };
        };
        userTasks = [
          {
            label = "typenix: check";
            command = typenix;
            args = ["--noEmit"];
          }
        ];
        enableMcpIntegration = true;
        installRemoteServer = !pkgs.stdenv.hostPlatform.isDarwin;
      };
    };
  };
}
