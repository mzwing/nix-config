{
  mzwing.features."software/java" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    darwin = {pkgs, ...}: {
      environment.systemPackages = with pkgs; [
        graalvmPackages.graalvm-ce
      ];
    };

    home = {pkgs, ...}: {
      programs.java = {
        enable = true;
        package = pkgs.openjdk17;
      };
    };
  };
}
