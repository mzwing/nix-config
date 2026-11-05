{
  mzwing.features."nixos/server/azure" = {
    meta.platforms = ["nixos"];

    nixos = {modulesPath, ...}: {
      imports = [
        (modulesPath + "/virtualisation/azure-common.nix")
      ];

      # azure-common brings cloud-init along, and its update_hostname would rename the box to the Azure VM name.
      services.cloud-init.settings.preserve_hostname = true;
    };
  };
}
