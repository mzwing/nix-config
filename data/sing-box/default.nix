# The fragments each profile merges, in order. Proxies stay out of here: clients merge the sing-box/client/* secrets, and each server its sing-box/<host>/inbounds.
let
  client = [
    "log.json"
    "dns/servers/local.json"
    "dns/servers/dohna.json"
    "dns/servers/dnspod.json"
    "dns/servers/mzwing-tailscale.json"
    "dns/common.json"
    "dns/rules/client/common.json"
    "inbounds/mixed.json"
    "outbounds/common.json"
    "endpoints/tailscale/mzwing.json"
    "http_clients.json"
    "experimental/common.json"
    "experimental/clash-api.json"
    "services/sing-box-api.json"
    "routes/rules/client/common.json"
    "routes/rule-sets/common.json"
    "routes/rule-sets/client.json"
  ];

  # An exit's rules follow the steering ones and precede every catch-all, the DNS ones included
  serverWith = exits:
    [
      "log.json"
      "dns/servers/cloudflare-ipv4.json"
      "dns/servers/mzwing-tailscale.json"
      "dns/common.json"
      "dns/strategy/ipv4.json"
      "inbounds/tun/linux.json"
      "outbounds/common.json"
      "endpoints/tailscale/server.json"
      "http_clients.json"
      "experimental/common.json"
      "routes/rules/server.json"
    ]
    ++ exits
    ++ [
      "dns/rules/server.json"
      "routes/rules/server-fallback.json"
      "routes/rule-sets/common.json"
      "routes/rule-sets/server.json"
    ];
in {
  macos = client ++ ["inbounds/tun/common.json"];
  android = client ++ ["inbounds/tun/common.json" "routes/android.json"];
  linux = client ++ ["inbounds/tun/linux.json"];

  server = serverWith [];
  # Netflix, ChatGPT and all of IPv6 leave through WARP, for a server that picks software/network/sing-box-warp
  server-warp = serverWith ["dns/rules/warp.json" "routes/rules/warp.json"];

  # Every client also merges these once its own speed-test results are filled in.
  measured = ["dns/servers/google-pin.json"];
}
