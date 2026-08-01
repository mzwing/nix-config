{
  mzwing.features."nixos/server/upcloud" = {
    meta.platforms = ["nixos"];

    nixos = {modulesPath, ...}: {
      imports = [
        (modulesPath + "/profiles/qemu-guest.nix")
      ];
    };
  };
}
