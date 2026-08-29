# GnuPG, and whichever agent holds the keys. Same split as software/ssh: a desktop has Keyguard, a server has to run its own.
let
  # A GnuPG home rather than a bare socket — Keyguard binds its S.gpg-agent inside, and gpgconf resolves the rest from there.
  keyguardHomedir = home: "${home}/Library/Group Containers/com.artemchep.keyguard/gnupg";
in {
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

    home = {
      config,
      lib,
      pkgs,
      type,
      ...
    }: let
      # Nothing else provides that home, so a desktop selecting this has to select software/keyguard too.
      viaKeyguard = type == "desktop";
    in {
      programs.gpg = {
        enable = true;

        # Home Manager exports GNUPGHOME from this, which is all gpg and git need to reach the vault's keys.
        homedir = lib.mkIf viaKeyguard (keyguardHomedir config.home.homeDirectory);
      };

      # Keyguard already binds an agent in that home; a second one would just fight it.
      services.gpg-agent = lib.mkIf (!viaKeyguard) {
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
