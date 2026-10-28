let
  endpoint = import ../../../../data/magpie.nix;
  domain = "karakeep.service.mzwing.eu.org";
in {
  mzwing.features."software/utility/karakeep" = {
    meta.platforms = ["nixos"];

    requires = [
      "software/ai/magpie"
      "software/server/caddy"
    ];

    nixos = {
      config,
      lib,
      pkgs,
      ...
    }: let
      web = {
        host = "127.0.0.1";
        port = 3000;
      };
      chromiumAddress = "127.0.0.1:${toString config.services.karakeep.browser.port}";
      proxyAddress = "127.0.0.1:9223";
    in {
      services.karakeep = {
        enable = true;

        browser.exe = lib.getExe pkgs.ungoogled-chromium;

        extraEnvironment = {
          # Next.js' standalone server binds HOSTNAME, every interface unless told otherwise.
          HOSTNAME = web.host;
          PORT = toString web.port;
          NEXTAUTH_URL = "https://${domain}";

          DISABLE_SIGNUPS = "true";
          DISABLE_NEW_RELEASE_CHECK = "true";
          DB_WAL_MODE = "true";

          # A held connection would keep Chromium up for good.
          BROWSER_CONNECT_ONDEMAND = "true";

          OPENAI_BASE_URL = endpoint.baseUrl;
          # Loopback takes any key; this one names karakeep's requests in magpie.
          OPENAI_API_KEY = "magpie-karakeep";
          INFERENCE_TEXT_MODEL = "gpt-6-luna";
          INFERENCE_IMAGE_MODEL = "gpt-6-luna";
          # Reasoning models refuse max_tokens, and karakeep only switches by itself when it talks to OpenAI directly.
          INFERENCE_USE_MAX_COMPLETION_TOKENS = "true";
        };
      };

      services.caddy.virtualHosts.${domain}.extraConfig = "reverse_proxy ${web.host}:${toString web.port}";

      # Keeps Chromium off between crawls: a connection here starts it behind systemd-socket-proxyd, and both stop once the proxy has sat idle.
      systemd.sockets.karakeep-browser-proxy = {
        wantedBy = ["sockets.target"];
        listenStreams = [proxyAddress];
      };

      systemd.services = {
        karakeep-browser-proxy = {
          requires = ["karakeep-browser.service"];
          after = ["karakeep-browser.service"];
          serviceConfig = {
            ExecStart = "${config.systemd.package}/lib/systemd/systemd-socket-proxyd --exit-idle-time=5min ${chromiumAddress}";
            DynamicUser = true;
          };
        };

        karakeep-browser = {
          wantedBy = lib.mkForce [];
          unitConfig.StopWhenUnneeded = true;
          # Type=simple counts Chromium as up before it listens, and the proxy would dial into nothing.
          postStart = ''
            until ${lib.getExe pkgs.curl} -sf http://${chromiumAddress}/json/version > /dev/null; do
              sleep 0.2
            done
          '';
        };

        karakeep-web.environment.BROWSER_WEB_URL = lib.mkForce "http://${proxyAddress}";
        karakeep-workers.environment.BROWSER_WEB_URL = lib.mkForce "http://${proxyAddress}";
      };
    };
  };
}
