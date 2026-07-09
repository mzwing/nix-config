{
  mzwing.features."software/gaming" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    darwin.homebrew.casks = [
      "heroic"
      "xmcl"
    ];

    nixos = {pkgs, ...}: {
      environment.systemPackages = with pkgs; [
        heroic
      ];
    };

    home = {
      lib,
      pkgs,
      ...
    }:
      lib.mkIf pkgs.stdenv.isLinux {
        # TODO: complete Prism Launcher configuration
        programs.prismlauncher.enable = true;
      };
  };
}
