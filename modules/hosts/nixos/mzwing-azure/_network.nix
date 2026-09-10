{
  # The address needs no config of its own: Azure serves the private one over DHCP and NATs the public one at the platform.
  # This one line is the exception — Standard_B2ts_v2 gets accelerated networking, so an mlx5 VF rides along with eth0 and networkd must leave it alone.
  virtualisation.azure.acceleratedNetworking = true;
}
