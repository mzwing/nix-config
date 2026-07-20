{
  mzwing.features."nixos/server/network/do-sgp" = {
    meta.platforms = ["nixos"];

    nixos = {
      config,
      lib,
      inputs,
      ...
    }: {
      networking = {
        useDHCP = false;
        useNetworkd = true;
      };

      systemd.network.enable = true;

      age.secrets = {
        do-sgp-private-network = {
          file = "${inputs.self}/secrets/do-sgp/network/private.age";
          group = "systemd-network";
          mode = "0440";
          owner = "root";
          path = "/etc/systemd/network/20-private.network";
        };

        do-sgp-public-network = {
          file = "${inputs.self}/secrets/do-sgp/network/public.age";
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
    };
  };
}
