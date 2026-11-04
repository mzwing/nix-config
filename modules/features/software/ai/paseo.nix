{
  mzwing.features."software/ai/paseo" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    requires = [
      "darwin/homebrew"
      "home/agenix"
      "software/network/tailscale"
    ];

    darwin.homebrew.casks = ["paseo"];

    nixos = {
      config,
      hostname,
      inputs,
      lib,
      secrets,
      system,
      type,
      username,
      ...
    }: let
      hm = config.home-manager.users.${username};
    in {
      imports = [inputs.paseo.nixosModules.paseo];

      config = lib.mkMerge [
        {
          services.paseo = {
            enable = true;
            # Cached on cache.numtide.com, unlike the paseo flake's own
            package = inputs.llm-agents.packages.${system}.paseo;
            user = username;
            group = config.users.users.${username}.group;
            # The module guesses /home/<user>, which root's isn't
            dataDir = "${config.users.users.${username}.home}/.paseo";
            # No relay, so the apps dial the daemon over the tailnet; hostnames lets them use the MagicDNS name, not only the IP.
            relay.enable = false;
            hostnames = [hostname];
            settings.daemon.mcp.injectIntoAgents = true;
          };

          # settings is rendered into the world-readable store, so the password comes in as PASEO_PASSWORD instead.
          systemd.services.paseo.serviceConfig.EnvironmentFile =
            if type == "container"
            then hm.age.secrets.paseo-password.path
            else config.age.secrets.paseo-password.path;
        }

        (lib.mkIf (type != "container") {
          age.secrets.paseo-password.file = secrets."${lib.removePrefix "mzwing-" hostname}/paseo/password";

          services.paseo.listenAddress = "0.0.0.0";

          networking.firewall.interfaces.tailscale0.allowedTCPPorts = [config.services.paseo.port];
        })

        (lib.mkIf (type == "container") {
          # tailscaled runs in userspace there: it hands tailnet connections to loopback, where the daemon listens by default, and the agents reach magpie only through its proxy
          services.paseo.environment.HTTP_PROXY = hm.home.sessionVariables.HTTP_PROXY;

          # The module creates dataDir with tmpfiles, which can't run on CNB's 5.4 kernel
          systemd.services.paseo.preStart = lib.mkBefore "install -d -m 0700 ${config.services.paseo.dataDir}";
        })
      ];
    };

    # A container decrypts only the user's secrets, so the password is linked to where a system secret would land
    home = {
      hostname,
      lib,
      osConfig,
      secrets,
      type,
      ...
    }:
      lib.mkIf (type == "container") {
        age.secrets.paseo-password = {
          file = secrets."${lib.removePrefix "mzwing-" hostname}/paseo/password";
          path = "${osConfig.age.secretsDir}/paseo-password";
        };
      };
  };
}
