let
  endpoint = import ../../../data/magpie.nix;
in {
  mzwing.features."software/magpie" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    requires = ["darwin/homebrew"];

    system.services.magpie = {
      enable = true;
      inherit (endpoint) host port;
      # omp and pi name models without the provider, which magpie lists only with this on.
      settings.bareModelIDs = true;
      env.DO_NOT_TRACK = "1";
    };

    darwin = {
      config,
      inputs,
      username,
      ...
    }: {
      imports = [inputs.nur.repos.mzwing.modules.darwin.magpie];

      # Keep the app's own launch at login off: it would fight the agent for the port.
      homebrew.casks = ["magpie-app"];

      services.magpie.logFile = "${config.users.users.${username}.home}/Library/Logs/magpie.log";
    };

    nixos = {
      inputs,
      pkgs,
      type,
      username,
      ...
    }: {
      imports = [inputs.nur.repos.mzwing.modules.nixos.magpie];

      services.magpie = {
        package = pkgs.nur.repos.xyenon.magpie.override {guiSupport = type == "desktop";};
        user = username;
      };
    };
  };
}
