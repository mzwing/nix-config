let
  relayPort = 40000;
  userspaceProxy = "localhost:1055";
in {
  mzwing.features."software/network/tailscale" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    requires = [
      "darwin/homebrew"
      "home/agenix"
    ];

    darwin.homebrew.casks = ["tailscale-app"];

    nixos = {
      config,
      hostname,
      lib,
      secrets,
      type,
      username,
      ...
    }:
      lib.mkMerge [
        {
          services.tailscale = {
            enable = true;
            openFirewall = true;
            disableUpstreamLogging = true;
          };
        }

        (lib.mkIf (type == "server") {
          age.secrets.tailscale-oauth-secret.file = secrets."tailscale/oauth-secret";

          services.tailscale = {
            authKeyFile = config.age.secrets.tailscale-oauth-secret.path;
            # An OAuth secret registers ephemeral nodes by default, and those get deleted soon after going offline.
            authKeyParameters = {
              ephemeral = false;
              preauthorized = true;
            };
            extraUpFlags = ["--advertise-tags=tag:server"];
            extraSetFlags = ["--relay-server-port=${toString relayPort}"];
          };

          networking.firewall.allowedUDPPorts = [relayPort];
        })

        # Nothing promises a container a TUN device, nor a host key: tailscaled runs in userspace, and its key is the user's secret.
        (lib.mkIf (type == "container") {
          services.tailscale = {
            interfaceName = "userspace-networking";
            extraDaemonFlags = [
              "--state=mem:"
              "--socks5-server=${userspaceProxy}"
              "--outbound-http-proxy-listen=${userspaceProxy}"
            ];
            authKeyFile = config.home-manager.users.${username}.age.secrets.tailscale-oauth-secret.path;
            authKeyParameters = {
              ephemeral = true;
              preauthorized = true;
            };
            extraUpFlags = [
              "--advertise-tags=tag:container"
              # The runtime names the container, not NixOS.
              "--hostname=${hostname}"
            ];
          };
        })
      ];

    home = {
      lib,
      osConfig,
      pkgs,
      secrets,
      type,
      ...
    }: let
      tailscale = osConfig.services.tailscale.package;

      isTailnetPeer = pkgs.writeShellScript "is-tailnet-peer" ''
        ${lib.getExe tailscale} status --json 2>/dev/null | ${lib.getExe pkgs.jq} -e --arg host "$1" '[.Peer[]? | .TailscaleIPs[], (.DNSName | rtrimstr(".") | ., split(".")[0])] | index($host)' >/dev/null
      '';
    in
      lib.mkIf (type == "container") {
        age.secrets.tailscale-oauth-secret = {
          file = secrets."tailscale/oauth-secret";
          # tailscaled takes an absolute path, so the key is linked to where a system secret would land.
          path = "${osConfig.age.secretsDir}/tailscale-oauth-secret";
        };

        # In userspace mode only tailscaled can reach the tailnet, so ssh to a peer goes through it.
        programs.ssh.settings.tailnet = {
          header = ''Match exec "${isTailnetPeer} %h"'';
          ProxyCommand = "${lib.getExe tailscale} nc %h %p";
        };

        # Same for plain-http calls, such as the agents' to the servers' magpie.
        home.sessionVariables.HTTP_PROXY = "http://${userspaceProxy}";
      };
  };
}
