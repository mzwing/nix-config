{
  mzwing.features."nixos/server/digitalocean" = {
    meta.platforms = ["nixos"];

    nixos = {
      lib,
      modulesPath,
      ...
    }: {
      imports = [
        (modulesPath + "/virtualisation/digital-ocean-config.nix")
      ];

      # mkForce: disko lists /dev/vda as well, and grub rejects the duplicate.
      boot.loader.grub.devices = lib.mkForce ["/dev/vda"];
    };
  };
}
