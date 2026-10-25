{
  # The address needs no config of its own: the VPC serves the private one over DHCP and NATs the EIP at the platform.
  networking.useNetworkd = true;

  # tailscaled drops anything from 100.64.0.0/10 that doesn't come in on tailscale0, the VPC's DNS (100.125.1.250) included.
  networking.nameservers = ["223.5.5.5" "119.29.29.29"];
  systemd.network.networks."99-ethernet-default-dhcp".dhcpV4Config.UseDNS = false;

  # network/china-mirrors serves the same paths.
  mzwing.nix.unreachableSubstituters = ["https://cache.nixos.org"];
}
