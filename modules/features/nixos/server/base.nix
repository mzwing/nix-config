{
  mzwing.features."nixos/server/base" = {
    meta.platforms = ["nixos"];

    nixos = {hostname, ...}: {
      networking.hostName = hostname;
      boot.tmp.cleanOnBoot = true;
    };
  };
}
