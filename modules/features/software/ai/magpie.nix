{lib, ...}: let
  endpoint = import ../../../../data/magpie.nix;
in {
  mzwing.features."software/ai/magpie" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    # For checking a relay's models by hand, as magpie-verify does on a timer.
    packages.home = pkgs: [pkgs.nur.repos.mzwing.lmfpd];

    system.services.magpie = {
      enable = true;
      # Servers widen it to share the gateway on the tailnet.
      host = lib.mkDefault endpoint.host;
      inherit (endpoint) port;
      # omp and pi name models without the provider, which magpie lists only with this on.
      settings.bareModelIDs = true;
      env.DO_NOT_TRACK = "1";
    };

    darwin = {
      config,
      inputs,
      pkgs,
      system,
      username,
      ...
    }: {
      imports = [inputs.nur.repos.mzwing.modules.darwin.magpie];

      # Keep the app's own launch at login off: it would fight the agent for the port.
      services.magpie.package = inputs.magpie.packages.${system}.magpie;

      launchd.user.agents.magpie.path = [
        # A Claude subscription is answered through Claude Code.
        inputs.llm-agents.packages.${system}.claude-code
        # Antigravity is managed through its CLI since Google banned magpie's own sign-in
        (pkgs.nur.repos.mzwing.antigravity-cli-modified.override {
          inherit (inputs.llm-agents.packages.${system}) antigravity-cli;
        })
        # `path` replaces launchd's PATH instead of adding to it.
        "/usr/bin"
        "/bin"
        "/usr/sbin"
        "/sbin"
      ];

      services.magpie.logFile = "${config.users.users.${username}.home}/Library/Logs/magpie.log";
    };

    nixos = {
      config,
      hostname,
      inputs,
      lib,
      pkgs,
      secrets,
      system,
      type,
      username,
      ...
    }: let
      # A Claude subscription is answered through Claude Code, and `magpie accounts add claude` signs in with it from a shell. Antigravity is managed through its CLI since Google banned magpie's own sign-in
      agents = [
        inputs.llm-agents.packages.${system}.claude-code
        (pkgs.nur.repos.mzwing.antigravity-cli-modified.override {
          inherit (inputs.llm-agents.packages.${system}) antigravity-cli;
        })
      ];
      lmfpd = pkgs.nur.repos.mzwing.lmfpd;

      verifyConfig = (pkgs.formats.json {}).generate "magpie-verify.json" {
        gateway = endpoint.baseUrl;
        magpie = lib.getExe config.services.magpie.package;
        fpd = lib.getExe lmfpd;
        bank = "${lmfpd}/lib/node_modules/lmfpd/data/unified_bank.json";
        threshold = 0.7;
        # Signed-in subscriptions and vendors' own APIs are trusted, and checking them would spend their quota.
        excludeProviders = [
          "claude"
          "cline"
          "codex"
          "copilot"
          "cursor"
          "deepseek"
          "devin"
          "nvidia-nim"
          "opencode-zen-free"
          "openrouter"
          "trae-cn"
          "trae-global"
          "typesafe"
          "workbuddy"
          "workbuddy-ai"
          "qiqi-deepseek"
          "qiqi-kimi"
          "rmqg-gemini"
          "rmqg-gpt"
          "lbyxiaolizi-opencode-zen"
          "dzmm"
          "modelscope"
          "siliconflow"
          "codearts"
          "zed"
          "remote-magpie-cn"
          "remote-magpie-us"
          "wokey"
          "cupboard-misakacloud"
          "agy-cli"
          "devin"
        ];
        aliases = {
          # lm-detector fingerprints GPT-6 Astra and GPT-6.1 Sol as one model.
          "gpt-6.1-sol" = "gpt-6-astra";
          k3 = "kimi-k3";
        };
      };

      verify = pkgs.writers.writePython3 "magpie-verify" {
        flakeIgnore = [
          "E501"
          "W503"
        ];
      } (builtins.readFile ../../../../scripts/magpie_verify.py);
    in {
      imports = [inputs.nur.repos.mzwing.modules.nixos.magpie];

      config = lib.mkMerge [
        {
          services.magpie = {
            package = with inputs.magpie.packages.${system};
              if type == "desktop"
              then magpie
              else magpie-cli;
            user = username;
            # Only the desktop build wraps in nixpkgs' Bun; the one magpie downloads for plugins can't start on NixOS
            env.MAGPIE_BUN = lib.getExe pkgs.bun;
          };

          environment.systemPackages = agents;
          systemd.services.magpie.path = agents;

          # Runs as magpie's own user, so `magpie model disable` edits the settings the gateway reads.
          systemd.services.magpie-verify = {
            description = "Disable magpie models that error or whose fingerprint isn't the model they claim";
            after = ["magpie.service"];
            # A switch would otherwise restart a run in progress and wait for all of it.
            restartIfChanged = false;
            serviceConfig = {
              Type = "oneshot";
              User = username;
              ExecStart = "${verify} ${verifyConfig}";
            };
          };

          systemd.timers.magpie-verify = {
            wantedBy = ["timers.target"];
            timerConfig = {
              OnCalendar = "*-*-* 04,16:00:00";
              Persistent = true;
            };
          };
        }

        # Other machines call a server's gateway over the tailnet, each with its own gateway key: magpie only takes keyless requests from plain loopback
        (lib.mkIf (type == "server") {
          age.secrets.magpie-web-key.file = secrets."magpie-web/${hostname}";

          services.magpie = {
            host = "0.0.0.0";
            settings = {
              lan = true;
              # On by itself only with no agent here, and the Claude Code installed for subscriptions counts as one.
              gatewayMode = "on";
            };
            web = {
              enable = true;
              host = "0.0.0.0";
            };
          };

          # Holds MAGPIE_WEB_KEY=…, out of the world-readable store; one fixed key keeps the browser signed in across restarts.
          systemd.services.magpie.serviceConfig.EnvironmentFile = config.age.secrets.magpie-web-key.path;

          networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
            endpoint.port
            config.services.magpie.web.port
          ];
        })

        (lib.mkIf (hostname == endpoint.remote) {
          services.magpie = {
            env.MAGPIE_PUBLIC_URL = "https://${endpoint.publicDomain}";
            # Unshared, magpie refuses every request Caddy forwards.
            settings.lan = true;
          };

          # Forwarded headers mark visitors as remote, so they need a gateway key; magpie lets loopback in with any. Caddy sets them by itself and keeps no response timeout, so a model can think for minutes.
          services.caddy.virtualHosts.${endpoint.publicDomain}.extraConfig = ''
            reverse_proxy ${endpoint.host}:${toString endpoint.port} {
              # The peer is an EdgeOne node, which names the visitor here.
              header_up X-Real-IP {header.EO-Connecting-IP}
              header_up X-Forwarded-For {header.EO-Connecting-IP}

              # Token-at-a-time SSE: nothing may wait in a buffer.
              flush_interval -1
            }
          '';
        })
      ];
    };
  };
}
