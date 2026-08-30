let
  endpoint = import ../../../data/cliproxyapiplus.nix;

  # Copies, not symlinks: the plugin scan skips anything that is not a regular file.
  pluginsDir = pkgs:
    pkgs.runCommandLocal "cliproxyapiplus-plugins" {
      plugins = with pkgs.nur.repos.mzwing; [
        cpa-plugin-antigravity-coding-filter
      ];
    } ''
      mkdir -p "$out"
      for plugin in $plugins; do
        install -m444 -t "$out" "$plugin"/lib/cliproxyapiplus/plugins/*
      done
    '';

  serviceFor = user: {
    config,
    pkgs,
    secrets,
    ...
  }: {
    age.secrets = {
      cliproxyapiplus-api-key = {
        file = secrets."cliproxyapiplus/api-key";
        owner = user;
        group = user;
      };
      cliproxyapiplus-remote-secret-key = {
        file = secrets."cliproxyapiplus/remote-secret-key";
        owner = user;
        group = user;
      };
    };

    services.cliproxyapiplus = {
      enable = true;

      apiKeysPaths = [config.age.secrets.cliproxyapiplus-api-key.path];
      remoteSecretKeyPath = config.age.secrets.cliproxyapiplus-remote-secret-key.path;

      settings = {
        inherit (endpoint) host port;

        debug = false;
        logging-to-file = true;
        logs-max-total-size-mb = 10;
        codex-instructions-enabled = false;

        remote-management = {
          allow-remote = false;
          disable-control-panel = false;
        };

        # A store path, so the plugin set rolls back with the generation. The panel's plugin store cannot write there.
        plugins = {
          enabled = true;
          dir = "${pluginsDir pkgs}";

          configs.antigravity-coding-filter = {
            enabled = true;
            priority = 1;
            # "block" would 403 my own clients instead.
            mode = "rewrite";
            use_default_keywords = true;
          };
        };
      };
    };
  };
in {
  mzwing.features."software/cliproxyapiplus" = {
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
        (serviceFor "_cliproxyapiplus")
      ];

      # macOS makes /etc/ssh/ssh_host_* outside nix and may replace them; this key only decrypts secrets.
      age.identityPaths = ["${config.users.users.${username}.home}/.ssh/agenix"];
    };

    nixos = {inputs, ...}: {
      imports = [
        inputs.nur.repos.mzwing.modules.nixos.cliproxyapiplus
        (serviceFor "cliproxyapiplus")
      ];
    };
  };
}
