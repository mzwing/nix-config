let
  agentContext = import ../../../../../data/agent-context.nix;
in {
  mzwing.features."software/ai/harness/dsh" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    requires = [
      "software/vcs/git"
      "software/ai/magpie-client"
      # The wakatime plugin below only tracks once ~/.wakatime.cfg carries the key.
      "software/development/wakatime"
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
      package = inputs.llm-agents.packages.${system}.dsh;
      inherit (config.mzwing.magpie) gateways;

      keyEnv = name: "${lib.toUpper (builtins.replaceStrings ["-"] ["_"] name)}_API_KEY";

      keyArgs =
        lib.mapAttrsToList (
          name: gateway:
            if gateway.keyFile == null
            # Loopback takes any key; this is the one magpie names dsh's requests by.
            then "--set ${keyEnv name} magpie-dsh"
            else "--run ${lib.escapeShellArg ''export ${keyEnv name}="$(${lib.getExe' pkgs.coreutils "cat"} "${gateway.keyFile}")"''}"
        )
        gateways;

      dsh = pkgs.symlinkJoin {
        name = "dsh-wrapped-${package.version}";
        paths = [package];
        nativeBuildInputs = [pkgs.makeWrapper];
        postBuild = ''
          wrapProgram $out/bin/dsh \
            --suffix PATH : ${lib.makeBinPath (with pkgs; [git nodejs pnpm-bin.latest wakatime-cli])} \
            --set DSH_TELEMETRY_DISABLED 1 \
            ${lib.concatStringsSep " " keyArgs}
        '';
      };

      plugins = [
        "@agent-stash/dsh-autosuggest"
        "@agent-stash/dsh-message-edit"
        "@agent-stash/dsh-recall"
        # dsh-recall and dsh-autosuggest install it on first start, which the sync below would undo.
        "@agent-stash/dsh-stash-kit"
        "@agent-stash/init"
        "@dingyi222666/dsh-wakatime"
        "@michengai/dsh-btw"
        "dsh-notify-me"
      ];

      # Shipped with dsh but switched off. Adding the running version selects them.
      shippedPlugins = [
        "@deepseek-ai/dsh-experimental-agent-team-profile"
        "@deepseek-ai/dsh-experimental-auto-review"
        "@deepseek-ai/dsh-experimental-plugin-market-bundle"
        "@deepseek-ai/dsh-experimental-ralph-bundle"
        "@deepseek-ai/dsh-experimental-session-search"
        "@deepseek-ai/dsh-experimental-session-titles-bundle"
        "@deepseek-ai/dsh-experimental-terminal-bundle"
        "@deepseek-ai/dsh-experimental-tool-worktree"
        "@deepseek-ai/dsh-experimental-voice-input-bundle"
      ];

      efforts = levels: lib.genAttrs levels lib.id;

      mcpRow = serverName: transport: {
        id = "mcp-${serverName}";
        name = "@deepseek-ai/dsh-mcp-client";
        config = {inherit serverName;} // transport;
      };
    in {
      home.packages = [dsh];

      home.file = {
        ".dsh/AGENTS.md".text = ''
          ${agentContext.rules}

          When possible, ALWAYS use the builtin tools (like read, edit, etc.) instead of shell commands!

          NEVER overthinking!

          ${agentContext.codegraph}
        '';

        # Every profile reads this layer after its own patch, which stays the Web UI's to write.
        ".dsh/cordis.patch.yml".source = yamlFormat.generate "dsh-cordis.patch.yml" [
          {
            id = "llm-pi-ai";
            config.providers =
              lib.mapAttrs (name: gateway: {
                apiKeyEnv = keyEnv name;
                api = "openai-completions";
                baseURL = gateway.baseUrl;
                defaultContextWindow = 1000000;
                defaultInput = ["text" "image"];
                retryPolicy = {
                  mode = "normal";
                  maxRetries = 3;
                };
                # dsh cannot list this provider's models itself. The efforts are copied from magpie's /v1/models; a model declaring none never reasons.
                models = [
                  {
                    id = "deepseek-v4-pro";
                    input = ["text"];
                    reasoningEfforts = efforts ["high"];
                  }
                  {
                    id = "deepseek-flash";
                    reasoningEfforts = efforts ["low" "high"];
                  }
                  {
                    id = "claude-opus-5-5";
                    reasoningEfforts = efforts ["low" "medium" "high" "xhigh" "max"];
                  }
                  {
                    id = "gpt-6.1-sol";
                    reasoningEfforts = efforts ["low" "medium" "high" "xhigh"];
                  }
                  {
                    id = "k3";
                    reasoningEfforts = efforts ["low" "high" "xhigh"];
                  }
                ];
              })
              gateways;
          }
          {
            id = "agent-default-model";
            config = {
              provider = "magpie";
              model = "deepseek-flash";
              reasoningEffort = "high";
            };
          }
          {
            insert =
              lib.mapAttrsToList (
                name: server:
                  mcpRow name (
                    if server.url != null
                    then {
                      transport = "streamable-http";
                      inherit (server) url headers;
                    }
                    else {
                      transport = "stdio";
                      inherit (server) command args env;
                    }
                  )
              )
              config.programs.mcp.servers
              ++ [
                # pi gets Context7 from @upstash/context7-pi, which has no dsh counterpart.
                (mcpRow "context7" {
                  transport = "stdio";
                  command = lib.getExe pkgs.context7-mcp;
                })
              ];
          }
        ];
      };

      # Re-adding is how pnpm upgrades a plugin; any other package in the profile gets removed.
      home.activation.dshPlugins = lib.hm.dag.entryAfter ["linkGeneration"] ''
        run ${dsh}/bin/dsh plugin --profile web add ${lib.escapeShellArgs (plugins ++ map (name: "${name}@${package.version}") shippedPlugins)} \
          || warnEcho "dsh plugin install failed; the next activation retries it."
        for plugin in $(jq -r --argjson declared ${lib.escapeShellArg (builtins.toJSON (plugins ++ shippedPlugins))} '.dependencies | keys[] | select(IN($declared[]) | not)' ${config.home.homeDirectory}/.dsh/profiles/web/package.json); do
          run ${dsh}/bin/dsh plugin --profile web remove "$plugin"
        done
      '';
    };
  };
}
