{
  mzwing.features."software/ai/paseo" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    requires = ["darwin/homebrew"];

    darwin.homebrew.casks = ["paseo"];

    nixos = {
      config,
      hostname,
      inputs,
      secrets,
      username,
      ...
    }: {
      imports = [inputs.paseo.nixosModules.paseo];

      age.secrets.paseo-password.file = secrets."paseo/password";

      services.paseo = {
        enable = true;
        user = username;
        group = config.users.users.${username}.group;
        # No relay, so the apps dial the daemon over the tailnet; hostnames lets them use the MagicDNS name, not only the IP.
        relay.enable = false;
        listenAddress = "0.0.0.0";
        hostnames = [hostname];
        settings.daemon.mcp.injectIntoAgents = true;
      };

      # settings is rendered into the world-readable store, so the password comes in as PASEO_PASSWORD instead.
      systemd.services.paseo.serviceConfig.EnvironmentFile = config.age.secrets.paseo-password.path;

      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [config.services.paseo.port];
    };
  };
}
