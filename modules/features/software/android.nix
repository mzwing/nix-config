let
  systemAndroidModule = {pkgs, ...}: {
    environment.systemPackages = with pkgs; [
      android-tools
      payload-dumper-go
      samloader-rs
      scrcpy
    ];
  };
in {
  mzwing.features."software/android" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    darwin = systemAndroidModule;
    nixos = systemAndroidModule;
  };
}
