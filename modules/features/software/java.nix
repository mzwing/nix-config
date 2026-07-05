{
  mzwing.features."software/java" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    home = {pkgs, ...}: {
      programs.java = {
        enable = true;
        package = pkgs.graalvmPackages.graalvm-ce;
      };
    };
  };
}
