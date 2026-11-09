let
  relayPort = 40000;
  inherit (import ../../../../data/tailscale.nix) userspaceProxy;
in {
  mzwing.features."software/network/tailscale" = {
    meta.platforms = [
      "nixos"
    ];

    requires = [
      "home/agenix"
    ];

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

          # `tailscale up` swaps the OAuth secret for an auth key at api.tailscale.com, once, and tailscaled starts before the network is up.
          systemd.services.tailscaled-autoconnect = {
            wants = ["network-online.target"];
            after = ["network-online.target"];
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

          # systemctl3 counts a notify unit whose process exits after READY=1 as failed, failing the .cnb.yml stage that starts it
          systemd.services.tailscaled-autoconnect.serviceConfig.RemainAfterExit = true;
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

        # Same for plain-http calls
        home.sessionVariables.HTTP_PROXY = "http://${userspaceProxy}";
      };
  };
}
