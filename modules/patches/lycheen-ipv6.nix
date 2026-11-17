{
  # The provider doesn't route lycheen's IPv6 prefix, and sing-box's TUN completes every handshake locally, so clients never fall back from AAAA to IPv4 and get reset. Drop once the provider fixes it
  mzwing.hosts.nixos.mzwing-lycheen-us.modules = [
    ({lib, ...}: {
      services.sing-box.settings.dns.rules = lib.mkBefore [
        {
          query_type = ["AAAA"];
          action = "predefined";
          rcode = "NOERROR";
        }
      ];
    })
  ];
}
