{
  mzwing.features."home/base" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    home = {
      system,
      username,
      ...
    }: let
      homeDirectory =
        if system == "aarch64-darwin" || system == "x86_64-darwin"
        then "/Users/${username}"
        else "/home/${username}";
    in {
      programs.home-manager.enable = true;

      home = {
        inherit username homeDirectory;
        stateVersion = "26.11";

        # Keep interactive shells consistently UTF-8 and opt out of noisy tool telemetry by default.
        sessionVariables = {
          LANG = "zh_CN.UTF-8";
          LANGUAGE = "zh_CN";
          DO_NOT_TRACK = 1;
          HOMEBREW_NO_ANALYTICS = 1;
          NEXT_TELEMETRY_DISABLED = 1;
          NUXT_TELEMETRY_DISABLED = 1;
          TELEMETRY_DISABLED = 1;
        };
      };
    };
  };
}
