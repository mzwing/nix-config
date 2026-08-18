{
  mzwing.features."nixos/server" = {
    meta.platforms = ["nixos"];

    nixos = {hostname, ...}: {
      networking.hostName = hostname;
      boot.tmp.cleanOnBoot = true;
    };
  };
}
