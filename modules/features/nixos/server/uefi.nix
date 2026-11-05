{
  mzwing.features."nixos/server/uefi" = {
    meta.platforms = ["nixos"];

    nixos.boot.loader.grub = {
      # The removable path needs no EFI boot entry, which the firmware may drop
      device = "nodev";
      efiSupport = true;
      efiInstallAsRemovable = true;

      # Text mode, so GRUB is visible on the serial console — the only way in once boot breaks.
      font = null;
      splashImage = null;
    };
  };
}
