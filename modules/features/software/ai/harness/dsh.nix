{
  mzwing.features."software/ai/harness/dsh" = {
    meta.platforms = ["darwin"];

    requires = [
      "software/ai/magpie-client"
      "software/browser/yab"
      # Its tools come from devenv, as its instructions say
      "software/development/tools"
    ];

    home = {
      config,
      inputs,
      lib,
      osConfig,
      pkgs,
      system,
      ...
    }: let
      yamlFormat = pkgs.formats.yaml {};
      package = inputs.llm-agents.packages.${system}.dsh;
      inherit (config.mzwing.magpie) gateway;
      workspace = "${config.home.homeDirectory}/repos/cache/dsh";

      keyArg =
        if gateway.keyFile == null
        # Loopback takes any key; this is the one magpie names dsh's requests by.
        then "--set MAGPIE_API_KEY magpie-dsh"
        else "--run ${lib.escapeShellArg ''export MAGPIE_API_KEY="$(${lib.getExe' pkgs.coreutils "cat"} "${gateway.keyFile}")"''}";

      dsh = pkgs.symlinkJoin {
        name = "dsh-wrapped-${package.version}";
        paths = [package];
        nativeBuildInputs = [pkgs.makeWrapper];
        postBuild = ''
          wrapProgram $out/bin/dsh \
            --suffix PATH : ${lib.makeBinPath (with pkgs; [git nodejs pnpm-bin.latest])} \
            --set DSH_TELEMETRY_DISABLED 1 \
            ${keyArg}
        '';
      };

      plugins = [
        "@mzwing/dsh-auto-review"
        "@mzwing/dsh-model-info"
        "@xmanrui/dsh-im"
        # Brings its own memory tools, whose memory_read and memory_search clash with dsh-auto-memory's
        "dsh-soul-md"
      ];

      # Shipped with dsh but switched off. Adding the running version selects them.
      shippedPlugins = [
        "@deepseek-ai/dsh-experimental-session-search"
        "@deepseek-ai/dsh-experimental-session-titles-bundle"
      ];
    in {
      home.packages = [dsh];

      home.file = {
        ".dsh/AGENTS.md".text = ''
          You are mzwing's personal assistant, running on their MacBook. You organize their notes and calendar, plan trips, turn lecture recordings and their transcripts into notes, and talk ideas through with them.

          Your workspace is ${workspace}; keep your files there.

          Get tools from nix instead of asking mzwing to install them: keep the ones you reuse in the workspace's devenv.nix (`devenv init` creates it) and run them with `devenv shell -- <command>`; run a one-off with `nix run nixpkgs#<package> -- <args>`.

          Reply in Simplified Chinese.
        '';

        # Every profile reads this layer after its own patch, which stays the Web UI's to write.
        ".dsh/cordis.patch.yml".source = yamlFormat.generate "dsh-cordis.patch.yml" [
          {
            id = "llm-pi-ai";
            config.providers.magpie = {
              apiKeyEnv = "MAGPIE_API_KEY";
              api = "openai-completions";
              baseURL = gateway.baseUrl;
              defaultContextWindow = 1000000;
              defaultInput = ["text" "image"];
              retryPolicy = {
                mode = "normal";
                maxRetries = 3;
              };
              # dsh-model-info expands `*` to every model magpie lists and fills each in from the pi.dev and models.dev catalogs
              models = [
                {
                  # The catalogs settle on OpenAI's own 272k, below what any of magpie's routes serves
                  id = "auto/gpt-6.1-sol";
                  contextWindow = 1000000;
                }
                {id = "*";}
              ];
            };
          }
          {
            id = "model-info";
            config.providers.magpie = {};
          }
          {
            id = "agent-default-model";
            config = {
              provider = "magpie";
              model = "auto/gemini-3.8-flash";
              reasoningEffort = "high";
            };
          }
          {
            id = "auto-reviewer";
            config = {
              preset = "claude-code";
              provider = "magpie";
              model = "auto/claude-sonnet-5-5";
              autoMode = {
                hard_deny = [
                  "$defaults"
                  "Git Push: sending commits, branches, bookmarks or tags to a remote, through `git push`, `jj git push` or anything else."
                ];
                soft_deny = [
                  "$defaults"
                  "Git Commit [must name: the commit]: committing through `git commit`, `jj commit` or anything else that creates commits. `git add` and read-only git commands are not commits."
                ];
              };
            };
          }
          {
            insert = [
              {
                id = "mcp-yab-browser";
                name = "@deepseek-ai/dsh-mcp-client";
                config = {
                  serverName = "yab-browser";
                  transport = "stdio";
                  inherit (config.programs.mcp.servers.yab-browser) command args env;
                };
              }
            ];
          }
        ];
      };

      home.activation = {
        # launchd refuses a missing working directory
        dshWorkspace = lib.hm.dag.entryBetween ["setupLaunchAgents"] ["writeBoundary"] ''
          run mkdir -p ${lib.escapeShellArg workspace}
        '';

        # Re-adding is how pnpm upgrades a plugin; any other package in the profile gets removed.
        # Ahead of launchd, so dsh boots with them
        dshPlugins = lib.hm.dag.entryBetween ["setupLaunchAgents"] ["linkGeneration"] ''
          # pnpm otherwise holds back releases younger than a day, and refuses a remove while the lockfile holds one
          PNPM_CONFIG_MINIMUM_RELEASE_AGE=0 run ${dsh}/bin/dsh plugin --profile web add ${lib.escapeShellArgs (plugins ++ map (name: "${name}@${package.version}") shippedPlugins)} \
            || warnEcho "dsh plugin install failed; the next activation retries it."
          for plugin in $(jq -r --argjson declared ${lib.escapeShellArg (builtins.toJSON (plugins ++ shippedPlugins))} '.dependencies | keys[] | select(IN($declared[]) | not)' ${config.home.homeDirectory}/.dsh/profiles/web/package.json); do
            PNPM_CONFIG_MINIMUM_RELEASE_AGE=0 run ${dsh}/bin/dsh plugin --profile web remove "$plugin"
          done
        '';
      };

      launchd.agents.dsh = {
        enable = true;
        config = {
          ProgramArguments = ["${dsh}/bin/dsh" "web" "--no-open"];
          # launchd hands agents a bare PATH; this is the one nix-darwin gives shells, Homebrew first as in them
          EnvironmentVariables.PATH = lib.concatStringsSep ":" (
            lib.optional osConfig.homebrew.enable "${osConfig.homebrew.prefix}/bin"
            ++ [(lib.replaceStrings ["$HOME" "$USER"] [config.home.homeDirectory config.home.username] osConfig.environment.systemPath)]
          );
          # Sessions opened without a directory start here
          WorkingDirectory = workspace;
          RunAtLoad = true;
          KeepAlive = true;
          StandardOutPath = "${config.home.homeDirectory}/Library/Logs/dsh.log";
          StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/dsh.log";
        };
      };
    };
  };
}
