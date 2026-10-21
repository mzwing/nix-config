{lib, ...}: let
  endpoint = import ../../../../data/magpie.nix;
in {
  mzwing.features."software/ai/magpie" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    requires = ["darwin/homebrew"];

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
      system,
      username,
      ...
    }: {
      imports = [inputs.nur.repos.mzwing.modules.darwin.magpie];

      # Keep the app's own launch at login off: it would fight the agent for the port.
      homebrew.casks = ["magpie-app"];

      launchd.user.agents.magpie.path = [
        # A Claude subscription is answered through Claude Code.
        inputs.llm-agents.packages.${system}.claude-code
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
      inputs,
      lib,
      pkgs,
      system,
      type,
      username,
      ...
    }: let
      inherit (inputs.llm-agents.packages.${system}) claude-code;
      lmfpd = pkgs.nur.repos.mzwing.lmfpd;

      verifyConfig = (pkgs.formats.json {}).generate "magpie-verify.json" {
        gateway = endpoint.baseUrl;
        magpie = lib.getExe config.services.magpie.package;
        fpd = lib.getExe lmfpd;
        bank = "${lmfpd}/lib/node_modules/lmfpd/data/unified_bank.json";
        threshold = 0.7;
        # Signed-in subscriptions and vendors' own APIs are trusted, and checking them would spend their quota.
        excludeProviders = [
          "antigravity"
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
          "rikki-glm"
          "qiqi-kimi"
          "rmqg-gpt"
          "lbyxiaolizi-opencode-zen"
          "dzmm"
          ""
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
            package = pkgs.nur.repos.xyenon.magpie.override {guiSupport = type == "desktop";};
            user = username;
          };

          # A Claude subscription is answered through Claude Code, and `magpie accounts add claude` signs in with it from a shell.
          environment.systemPackages = [claude-code];
          systemd.services.magpie.path = [claude-code];

          # Runs as magpie's own user, so `magpie model disable` edits the settings the gateway reads.
          systemd.services.magpie-verify = {
            description = "Disable magpie models whose fingerprint isn't the model they claim";
            after = ["magpie.service"];
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

        # Machines without a gateway of their own call the servers' over the tailnet, each with its own gateway key: magpie only takes keyless requests from plain loopback.
        (lib.mkIf (type == "server") {
          services.magpie = {
            host = "0.0.0.0";
            settings.lan = true;
          };

          networking.firewall.interfaces.tailscale0.allowedTCPPorts = [endpoint.port];
        })
      ];
    };
  };
}
