# The local CLI proxy: the service, plus its API key for clients like software/pi-coding-agent.
let
  endpoint = import ../../../data/cliproxyapiplus.nix;

  cliproxyapiplusService = {
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
      secrets,
      username,
      ...
    }: {
      imports = [
        inputs.agenix.darwinModules.default
        inputs.nur.repos.mzwing.modules.darwin.cliproxyapiplus
      ];

      # Same recipients as the Home Manager copy, so root decrypts with the user's key.
      age.identityPaths = ["${config.users.users.${username}.home}/.ssh/server_key"];
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
        cliproxyapiplusService
        // {
          apiKeysPaths = [config.age.secrets.cliproxyapiplus-api-key.path];
          remoteSecretKeyPath = config.age.secrets.cliproxyapiplus-remote-secret-key.path;
        };
    };

    nixos = {
      config,
      inputs,
      secrets,
      username,
      ...
    }: {
      imports = [
        inputs.nur.repos.mzwing.modules.nixos.cliproxyapiplus
      ];

      age.identityPaths = ["${config.users.users.${username}.home}/.ssh/server_key"];
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
        cliproxyapiplusService
        // {
          apiKeysPaths = [config.age.secrets.cliproxyapiplus-api-key.path];
          remoteSecretKeyPath = config.age.secrets.cliproxyapiplus-remote-secret-key.path;
        };
    };

    # The same key for the user: clients cannot read the service's copy.
    home = {
      config,
      inputs,
      secrets,
      ...
    }: {
      imports = [
        inputs.agenix.homeManagerModules.default
      ];

      age.identityPaths = [
        "${config.home.homeDirectory}/.ssh/server_key"
      ];
      age.secrets."cliproxyapiplus-api-key".file = secrets."cliproxyapiplus/api-key";
    };
  };
}
