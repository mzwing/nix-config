{
  mzwing.features."software/server/pumpkin" = {
    meta.platforms = ["nixos"];

    nixos = {pkgs, ...}: {
      services.pumpkin = {
        enable = true;

        # rustc 1.99 overflows its default stack compiling pumpkin-data. Drop once nixpkgs' pumpkin builds again.
        package = pkgs.pumpkin.overrideAttrs (old: {
          env = old.env // {RUST_MIN_STACK = "33554432";};
        });

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
