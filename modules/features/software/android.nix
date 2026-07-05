let
  systemAndroidPackages = pkgs:
    with pkgs; [
      payload-dumper-go
      scrcpy
    ];

  systemAndroidModule = {pkgs, ...}: {
    environment.systemPackages = systemAndroidPackages pkgs;
  };
in {
  mzwing.features."software/android" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    darwin = {pkgs, ...}: {
      environment.systemPackages = systemAndroidPackages pkgs;
      homebrew = {
        brews = [
          "samloader-rs"
        ];
        casks = [
          "android-commandlinetools"
          "android-platform-tools"
        ];
      };
    };

    nixos = systemAndroidModule;
  };
}
