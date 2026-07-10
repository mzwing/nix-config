{
  mzwing.features."nixos/server/zram" = {
    meta.platforms = ["nixos"];

    nixos = {
      zramSwap.enable = true;
    };
  };
}
