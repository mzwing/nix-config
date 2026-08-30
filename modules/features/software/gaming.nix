{
  mzwing.features."software/gaming" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    requires = ["darwin/homebrew"];

    packages.nixos = pkgs: [pkgs.heroic];

    darwin.homebrew.casks = [
      "heroic"
      "xmcl"
    ];

    home = {
      lib,
      pkgs,
      ...
    }:
      lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
        # TODO: complete Prism Launcher configuration
        programs.prismlauncher.enable = true;
      };
  };
}
