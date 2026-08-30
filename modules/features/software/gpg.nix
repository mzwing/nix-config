{
  mzwing.features."software/gpg" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    packages.nixos = pkgs: [pkgs.gnupg];

    home = {pkgs, ...}: {
      programs.gpg.enable = true;

      services.gpg-agent = {
        enable = true;
        pinentry.package =
          if pkgs.stdenv.hostPlatform.isDarwin
          then pkgs.pinentry_mac
          else pkgs.pinentry-curses;
        enableFishIntegration = true;
      };
    };
  };
}
