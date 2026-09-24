{
  mzwing.features."software/paseo" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    requires = ["darwin/homebrew"];

    darwin.homebrew.casks = ["paseo"];

    nixos = {
      config,
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
        relay.enable = false;
        settings.daemon.mcp.injectIntoAgents = true;
      };

      # settings is rendered into the world-readable store, so the password comes in as PASEO_PASSWORD instead.
      systemd.services.paseo.serviceConfig.EnvironmentFile = config.age.secrets.paseo-password.path;
    };
  };
}
