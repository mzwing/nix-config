# Written by hand so the flake evaluates before the first install; `just nixos-anywhere` overwrites it with the generated one.
{lib, ...}: {
  boot.initrd.availableKernelModules = ["hv_storvsc" "sd_mod" "sr_mod"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = [];
  boot.extraModulePackages = [];

  # What nixos-generate-config emits for a Hyper-V guest, which is what an Azure VM is.
  virtualisation.hypervGuest.enable = true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
