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
      options.mzwing.magpie.gateways = lib.mkOption {
        type = lib.types.attrsOf (lib.types.attrsOf (lib.types.nullOr lib.types.str));
        readOnly = true;
        description = "The gateways agents call, by the provider name they give each: its `baseUrl`, and a `keyFile` holding this machine's gateway key, null on loopback, which takes any key.";
      };

      # A machine running a gateway calls its own; any other calls the ones its servers share on the tailnet.
      config =
        if osConfig.services.magpie.enable or false
        then {
          mzwing.magpie.gateways.magpie = {
            inherit (endpoint) baseUrl;
            keyFile = null;
          };
        }
        else {
          age.secrets = lib.mapAttrs' (name: server: lib.nameValuePair "${name}-key" {file = secrets."magpie/${server}/${hostname}";}) endpoint.remotes;

          mzwing.magpie.gateways =
            lib.mapAttrs (name: server: {
              baseUrl = "http://${server}:${toString endpoint.port}/v1";
              keyFile = config.age.secrets."${name}-key".path;
            })
            endpoint.remotes;
        };
    };
  };
}
