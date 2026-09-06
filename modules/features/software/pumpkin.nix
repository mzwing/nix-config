{
  mzwing.features."software/pumpkin" = {
    meta.platforms = ["nixos"];

    nixos = {
      services.pumpkin = {
        enable = true;

        # Reads the port back out of settings.networking.java.address.
        openFirewall = true;

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
              address = "0.0.0.0:8880";
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
