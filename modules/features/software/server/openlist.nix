let
  address = "127.0.0.1";
  port = 5244;
in {
  mzwing.features."software/server/openlist" = {
    meta.platforms = ["nixos"];

    requires = ["software/server/caddy"];

    nixos = {
      inputs,
      site,
      ...
    }: {
      imports = [inputs.nur.repos.mzwing.modules.nixos.openlist];

      services.openlist = {
        enable = true;
        env = {
          OPENLIST_SITE_URL = "https://${site}";
          OPENLIST_ADDR = address;
          OPENLIST_HTTP_PORT = toString port;
        };
      };

      # Reached directly, not through EdgeOne: naive answers on the same name, so this is what a visitor without proxy credentials finds there.
      services.caddy.virtualHosts.${site} = {
        behindEdgeOne = false;
        extraConfig = "reverse_proxy ${address}:${toString port}";
      };
    };
  };
}
