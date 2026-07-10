{
  # TODO: It's still a placeholder.
  mzwing.features."nixos/desktop" = {
    meta.platforms = ["nixos"];

    nixos = {
      pkgs,
      lib,
      ...
    }: {
      networking.networkmanager.enable = true;

      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;
      boot.loader.systemd-boot.configurationLimit = lib.mkDefault 10;
      boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;

      security.rtkit.enable = true;
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        pulse.enable = true;
        wireplumber.enable = true;
      };
      services.pulseaudio.enable = false;
    };
  };
}
