{
  # The address needs no config of its own: the VPC serves the private one over DHCP and NATs the EIP at the platform.
  networking.useNetworkd = true;

  # network/china-mirrors serves the same paths.
  mzwing.nix.unreachableSubstituters = ["https://cache.nixos.org"];
}
