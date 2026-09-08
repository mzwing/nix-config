{
  config,
  lib,
  secrets,
  ...
}: {
  networking = {
    useDHCP = false;
    useNetworkd = true;
  };

  systemd.network.enable = true;

  # Single NIC, matched by MAC inside the secret, so it needs no .link rename the way upcloud-sg does.
  age.secrets.wap-public-network = {
    file = secrets."wap/network/public";
    group = "systemd-network";
    mode = "0440";
    owner = "root";
    path = "/etc/systemd/network/10-public.network";
  };

  system.activationScripts.agenixInstall.deps = lib.mkAfter ["etc"];

  systemd.services.systemd-networkd.reloadTriggers = [
    config.age.secrets.wap-public-network.file
  ];
}
