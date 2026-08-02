let
  javaPort = 8880;

  pumpkinService = {
    enable = true;

    settings = {
      allow_chat_reports = false;

      logging.color = true;

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
in {
  mzwing.features."software/pumpkin" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    darwin = {inputs, ...}: {
      imports = [
        inputs.nur.repos.mzwing.modules.darwin.pumpkin
      ];

      services.pumpkin = pumpkinService;
    };

    nixos = {inputs, ...}: {
      imports = [
        inputs.nur.repos.mzwing.modules.nixos.pumpkin
      ];

      networking.firewall.allowedTCPPorts = [javaPort];

      services.pumpkin = pumpkinService;
    };
  };
}
