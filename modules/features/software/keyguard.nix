# The vault client that holds the keys. It serves an SSH agent and a GPG agent once unlocked; software/ssh and software/gpg are what point at them.
# Darwin only: the Linux build binds under $XDG_RUNTIME_DIR, which no static path can spell.
{
  mzwing.features."software/keyguard" = {
    meta.platforms = ["darwin"];

    darwin = {
      lib,
      pkgs,
      ...
    }: {
      homebrew.casks = ["keyguard"];

      # The DMG ships this helper without an exec bit, and the GPG agent then never starts. Appended to the homebrew step because every upgrade puts the bad mode back.
      system.activationScripts.homebrew.text = let
        agent = "/Applications/Keyguard.app/Contents/app/resources/keyguard-gpg-agent";
        chmod = lib.getExe' pkgs.coreutils "chmod";
      in
        lib.mkAfter ''
          if [ -f "${agent}" ]; then
            echo >&2 "Allpw Keyguard's GPG agent to execute..."
            ${chmod} +x "${agent}"
          fi
        '';
    };
  };
}
