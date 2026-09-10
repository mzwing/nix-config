{
  mzwing.features."nixos/server/azure" = {
    meta.platforms = ["nixos"];

    nixos = {modulesPath, ...}: {
      imports = [
        (modulesPath + "/virtualisation/azure-common.nix")
      ];

      # azure-common brings cloud-init along, and its update_hostname would rename the box to the Azure VM name.
      services.cloud-init.settings.preserve_hostname = true;

      boot.loader.grub = {
        # Gen2 VMs boot UEFI only, and the removable path still boots if Azure loses the EFI entry.
        device = "nodev";
        efiSupport = true;
        efiInstallAsRemovable = true;

        # Text mode, so GRUB is visible on the serial console — the only way in once boot breaks.
        font = null;
        splashImage = null;
      };
    };
  };
}
