let
  systemAndroidSdkModule = {pkgs, ...}: let
    androidComposition = pkgs.androidenv.composeAndroidPackages {
      buildToolsVersions = [
        "28.0.3"
        "33.0.1"
        "34.0.0"
        "35.0.0"
        "36.0.0"
      ];
      platformVersions = [
        "34"
        "35"
        "36.1"
      ];
      includeEmulator = "if-supported";
      includeCmake = true;
      cmakeVersions = [
        "3.22.1"
        "4.1.2"
      ];
      includeNDK = true;
      ndkVersions = [
        "25.1.8937393"
        "28.2.13676358"
      ];
    };

    androidSdk = androidComposition.androidsdk;
  in {
    environment.systemPackages = [androidSdk];

    environment.variables = {
      ANDROID_HOME = "${androidSdk}/libexec/android-sdk";
      ANDROID_NDK_ROOT = "${androidSdk}/libexec/android-sdk/ndk-bundle";
      ANDROID_SDK_ROOT = "${androidSdk}/libexec/android-sdk";
    };
  };
in {
  mzwing.features."software/android-sdk" = {
    meta = {
      platforms = [
        "darwin"
        "nixos"
      ];
      ci.mode = "local-only";
    };

    darwin = systemAndroidSdkModule;
    nixos = systemAndroidSdkModule;
  };
}
