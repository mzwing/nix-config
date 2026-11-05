{
  config,
  lib,
  secrets,
  ...
}: {
  # No DHCP here: the provider's cloud-init seed sets the addresses statically, and the secret repeats them
  networking = {
    useDHCP = false;
    useNetworkd = true;
  };

  age.secrets.lycheen-us-public-network = {
    file = secrets."lycheen-us/network/public";
    group = "systemd-network";
    mode = "0440";
    owner = "root";
    path = "/etc/systemd/network/10-public.network";
  };

  system.activationScripts.agenixInstall.deps = lib.mkAfter ["etc"];

  systemd.services.systemd-networkd.reloadTriggers = [
    config.age.secrets.lycheen-us-public-network.file
  ];
}
