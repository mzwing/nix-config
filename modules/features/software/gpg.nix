{
  mzwing.features."software/gpg" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    nixos = {pkgs, ...}: {
      environment.systemPackages = with pkgs; [
        gnupg
      ];
    };

    home = {pkgs, ...}: {
      programs.gpg.enable = true;

      services.gpg-agent = {
        enable = true;
        pinentry.package =
          if pkgs.stdenv.isDarwin
          then pkgs.pinentry_mac
          else pkgs.pinentry-curses;
        enableFishIntegration = true;
        enableSshSupport = true;
      };
    };
  };
}
