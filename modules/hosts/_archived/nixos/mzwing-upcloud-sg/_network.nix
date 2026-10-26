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

  systemd.network = {
    enable = true;

    links = {
      "10-upcloud-public-ipv4" = {
        matchConfig.PermanentMACAddress = "a2:1c:78:c5:5b:7c";
        linkConfig.Name = "eth0";
      };

      "10-upcloud-utility-ipv4" = {
        matchConfig.PermanentMACAddress = "a2:1c:78:c5:aa:50";
        linkConfig.Name = "eth1";
      };

      "10-upcloud-public-ipv6" = {
        matchConfig.PermanentMACAddress = "a2:1c:78:c5:27:70";
        linkConfig.Name = "eth2";
      };
    };
  };

  age.secrets = {
    upcloud-sg-public-ipv4-network = {
      file = secrets."upcloud-sg/network/public-ipv4";
      group = "systemd-network";
      mode = "0440";
      owner = "root";
      path = "/etc/systemd/network/10-upcloud-public-ipv4.network";
    };

    upcloud-sg-public-ipv6-network = {
      file = secrets."upcloud-sg/network/public-ipv6";
      group = "systemd-network";
      mode = "0440";
      owner = "root";
      path = "/etc/systemd/network/10-upcloud-public-ipv6.network";
    };

    upcloud-sg-utility-ipv4-network = {
      file = secrets."upcloud-sg/network/utility-ipv4";
      group = "systemd-network";
      mode = "0440";
      owner = "root";
      path = "/etc/systemd/network/10-upcloud-utility-ipv4.network";
    };
  };

  system.activationScripts.agenixInstall.deps = lib.mkAfter ["etc"];

  systemd.services.systemd-networkd.reloadTriggers = [
    config.age.secrets.upcloud-sg-public-ipv4-network.file
    config.age.secrets.upcloud-sg-public-ipv6-network.file
    config.age.secrets.upcloud-sg-utility-ipv4-network.file
  ];
}
