let
  endpoint = import ../../../../data/magpie.nix;
in {
  mzwing.features."software/ai/magpie-client" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    requires = ["home/agenix"];

    home = {
      config,
      hostname,
      lib,
      osConfig,
      secrets,
      ...
    }: {
      options.mzwing.magpie.gateway = lib.mkOption {
        type = lib.types.attrsOf (lib.types.nullOr lib.types.str);
        readOnly = true;
        description = "The gateway agents call: its `baseUrl`, and a `keyFile` holding this machine's gateway key, null on loopback, which takes any key.";
      };

      # A machine running a gateway calls its own; any other calls the remote's over the tailnet
      config =
        if osConfig.services.magpie.enable or false
        then {
          mzwing.magpie.gateway = {
            inherit (endpoint) baseUrl;
            keyFile = null;
          };
        }
        else {
          age.secrets.magpie-key.file = secrets."${lib.removePrefix "mzwing-" hostname}/magpie/${endpoint.remote}";

          mzwing.magpie.gateway = {
            baseUrl = "http://${endpoint.remote}:${toString endpoint.port}/v1";
            keyFile = config.age.secrets.magpie-key.path;
          };
        };
    };
  };
}
