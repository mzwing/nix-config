{
  mzwing.features."home/base" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    home = {
      programs.home-manager.enable = true;

      home = {
        stateVersion = "26.11";

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
