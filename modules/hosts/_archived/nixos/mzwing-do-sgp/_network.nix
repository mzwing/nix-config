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

  age.secrets = {
    do-sgp-private-network = {
      file = secrets."do-sgp/network/private";
      group = "systemd-network";
      mode = "0440";
      owner = "root";
      path = "/etc/systemd/network/20-private.network";
    };

    do-sgp-public-network = {
      file = secrets."do-sgp/network/public";
      group = "systemd-network";
      mode = "0440";
      owner = "root";
      path = "/etc/systemd/network/10-public.network";
    };
  };

  system.activationScripts.agenixInstall.deps = lib.mkAfter ["etc"];

  systemd.services.systemd-networkd.reloadTriggers = [
    config.age.secrets.do-sgp-private-network.file
    config.age.secrets.do-sgp-public-network.file
  ];
}
