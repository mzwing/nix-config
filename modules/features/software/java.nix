{
  mzwing.features."software/java" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    # This config is for running java programs like MC. If you want developing java programs, you should use devenv config in the `environments/java` .

    home = {pkgs, ...}: {
      programs.java = {
        enable = true;
        package = pkgs.graalvmPackages.graalvm-ce;
      };
    };
  };
}
