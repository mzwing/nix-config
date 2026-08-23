let
  javaPackage = pkgs: pkgs.graalvmPackages.graalvm-ce;
in {
  mzwing.features."software/java" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    # This config is for running java programs like MC. If you want developing java programs, you should use devenv config in the `environments/java` .
    # software/shell pulls it in on the servers too, where a whole GraalVM would be for nothing.

    darwin = {
      lib,
      pkgs,
      type,
      ...
    }: let
      java = javaPackage pkgs;
      javaBundle =
        java.bundle
        or (let
          infoPlist = (pkgs.formats.plist {}).generate "Info.plist" {
            CFBundleExecutable = "java";
            CFBundleIdentifier = "org.nixos.java";
            CFBundleInfoDictionaryVersion = "7.0";
            CFBundleName = java.pname;
            CFBundlePackageType = "BNDL";
            CFBundleShortVersionString = java.version;
            CFBundleVersion = java.version;
            JavaVM = {
              JVMCapabilities = ["CommandLine"];
              JVMPlatformVersion = java.version;
              JVMVendor = java.pname;
              JVMVersion = java.version;
            };
          };
        in
          pkgs.runCommand "${java.pname}-${java.version}.jdk" {} ''
            mkdir -p "$out/Contents/MacOS"
            ln -s "${java}" "$out/Contents/Home"
            ln -s "${java}/bin/java" "$out/Contents/MacOS/java"
            ln -s "${infoPlist}" "$out/Contents/Info.plist"
          '');
    in
      lib.mkIf (type == "desktop") {
        system.activationScripts.extraActivation.text = let
          ln = lib.getExe' pkgs.coreutils "ln";
          mkdir = lib.getExe' pkgs.coreutils "mkdir";
        in ''
          echo "linking Java into place..." >&2
          ${mkdir} -p "/Library/Java/JavaVirtualMachines"
          ${ln} -sfnT "${javaBundle}" "/Library/Java/JavaVirtualMachines/nix-java.jdk"
        '';
      };

    home = {
      lib,
      pkgs,
      type,
      ...
    }:
      lib.mkIf (type == "desktop") {
        programs.java = {
          enable = true;
          package = javaPackage pkgs;
        };
      };
  };
}
