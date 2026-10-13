let
  endpoint = import ../../../data/cliproxyapi.nix;

  secretNames = [
    "cliproxyapi-api-key"
    "cliproxyapi-management-key"
    "cliproxyapi-providers"
  ];

  # Copies, not symlinks: the plugin scan skips anything that is not a regular file.
  pluginsDir = pkgs:
    pkgs.runCommandLocal "cliproxyapi-plugins" {
      plugins = with pkgs.nur.repos.mzwing; [
        cpa-plugin-antigravity-coding-filter
      ];
    } ''
      mkdir -p "$out"
      for plugin in $plugins; do
        install -m444 -t "$out" "$plugin"/lib/cliproxyapiplus/plugins/*
      done
    '';

  service = {
    config,
    pkgs,
    secrets,
    ...
  }: {
    age.secrets = {
      cliproxyapi-api-key.file = secrets."cliproxyapi/api-key";
      cliproxyapi-management-key.file = secrets."cliproxyapi/management-key";
      cliproxyapi-providers.file = secrets."cliproxyapi/providers";
    };

    services.cliproxyapi = {
      enable = true;

      settings = {
        server = {inherit (endpoint) host port;};

        access.api-keys = [{_secret = config.age.secrets.cliproxyapi-api-key.path;}];

        # config.yaml is rewritten from Nix on every start, so channels added in the panel would not survive; they live in this secret instead, parsed as JSON.
        api-keys = {
          _secret = config.age.secrets.cliproxyapi-providers.path;
          quote = false;
        };

        # nginx fronts this on the server, so the panel has to accept non-loopback callers; the bcrypt secret key is what actually gates it.
        management = {
          allow-remote = true;
          secret-key._secret = config.age.secrets.cliproxyapi-management-key.path;
        };

        observability.logs = {
          logging-to-file = true;
          logs-max-total-size-mb = 10;
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
  mzwing.features."software/cliproxyapi" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    darwin = {
      config,
      inputs,
      lib,
      username,
      ...
    }: {
      imports = [
        inputs.agenix.darwinModules.default
        inputs.nur.repos.mzwing.modules.darwin.cliproxyapi
        service
      ];

      # launchd has no systemd credentials, so the service reads its secrets itself.
      age.secrets = lib.genAttrs secretNames (_: {
        owner = "_cliproxyapi";
        group = "_cliproxyapi";
      });

      # macOS makes /etc/ssh/ssh_host_* outside nix and may replace them; this key only decrypts secrets.
      age.identityPaths = ["${config.users.users.${username}.home}/.ssh/agenix"];
    };

    nixos = {config, ...}: {
      imports = [service];

      # Restarts once a secret is re-encrypted, e.g. after editing the channels. Hashed, since the .age path moves with every change to the flake.
      systemd.services.cliproxyapi.restartTriggers = map (name: builtins.hashFile "sha256" config.age.secrets.${name}.file) secretNames;
    };
  };
}
