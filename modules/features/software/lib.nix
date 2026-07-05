let
  systemLibModule = {pkgs, ...}: {
    environment.systemPackages = with pkgs; [
      libjpeg_turbo
      libogg
      libopenmpt
      libpng
      libvorbis
      llvmPackages.openmp
      mpg123
      rlottie
      SDL2
      sdl3
    ];
  };
in {
  mzwing.features."software/lib" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    darwin = systemLibModule;
    nixos = systemLibModule;
  };
}
