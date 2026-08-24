# The local CLI proxy: the service and its plugins.
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

  cliproxyapiplusService = pkgs: {
    enable = true;
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
in {
  mzwing.features."software/cliproxyapiplus" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    darwin = {
      config,
      inputs,
      pkgs,
      secrets,
      username,
      ...
    }: {
      imports = [
        inputs.agenix.darwinModules.default
        inputs.nur.repos.mzwing.modules.darwin.cliproxyapiplus
      ];

      # Not the agenix default (/etc/ssh/ssh_host_*): macOS makes those outside nix and may replace them. Root can read this one whatever its mode, and it decrypts secrets and nothing else.
      age.identityPaths = ["${config.users.users.${username}.home}/.ssh/agenix"];
      age.secrets = {
        cliproxyapiplus-api-key = {
          file = secrets."cliproxyapiplus/api-key";
          owner = "_cliproxyapiplus";
          group = "_cliproxyapiplus";
        };
        cliproxyapiplus-remote-secret-key = {
          file = secrets."cliproxyapiplus/remote-secret-key";
          owner = "_cliproxyapiplus";
          group = "_cliproxyapiplus";
        };
      };

      services.cliproxyapiplus =
        cliproxyapiplusService pkgs
        // {
          apiKeysPaths = [config.age.secrets.cliproxyapiplus-api-key.path];
          remoteSecretKeyPath = config.age.secrets.cliproxyapiplus-remote-secret-key.path;
        };
    };

    nixos = {
      config,
      inputs,
      pkgs,
      secrets,
      ...
    }: {
      imports = [
        inputs.nur.repos.mzwing.modules.nixos.cliproxyapiplus
      ];

      # Unlike darwin: nix owns the host keys here, so the agenix default holds. A NixOS host selecting this feature has to be added to the recipients in secrets/registry.nix.
      age.secrets = {
        cliproxyapiplus-api-key = {
          file = secrets."cliproxyapiplus/api-key";
          owner = "cliproxyapiplus";
          group = "cliproxyapiplus";
        };
        cliproxyapiplus-remote-secret-key = {
          file = secrets."cliproxyapiplus/remote-secret-key";
          owner = "cliproxyapiplus";
          group = "cliproxyapiplus";
        };
      };

      services.cliproxyapiplus =
        cliproxyapiplusService pkgs
        // {
          apiKeysPaths = [config.age.secrets.cliproxyapiplus-api-key.path];
          remoteSecretKeyPath = config.age.secrets.cliproxyapiplus-remote-secret-key.path;
        };
    };
  };
}
