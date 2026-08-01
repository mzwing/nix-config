let
  javaPort = 3389;
in {
  mzwing.features."software/pumpkin" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    nixos.networking.firewall.allowedTCPPorts = [javaPort];

    home = {inputs, ...}: {
      imports = [
        inputs.nur.repos.mzwing.modules.homeManager.pumpkin
      ];

      services.pumpkin = {
        enable = true;

        settings = {
          allow_chat_reports = false;

          logging.color = false;

          world.autosave_ticks = 6000;

          commands = {
            use_console = false;
            use_tty = false;
          };

          networking = {
            query.enabled = false;
            rcon.enabled = false;
            proxy.enabled = false;
            lan_broadcast.enabled = false;

            java = {
              enabled = true;
              address = "0.0.0.0:${toString javaPort}";
              encryption = true;
              online_mode = false;
              authentication.enabled = false;
            };

            bedrock.enabled = false;
          };
        };
      };
    };
  };
}
