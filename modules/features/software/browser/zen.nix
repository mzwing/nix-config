{
  mzwing.features."software/browser/zen" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    home = {
      inputs,
      lib,
      ...
    }: let
      extensions = lib.importJSON ../../../../data/zen/extensions.json;
    in {
      imports = [
        inputs.zen-browser.homeModules.beta
      ];

      programs.zen-browser = {
        enable = true;

        policies = {
          # Zen installs and updates these from AMO itself, and removes every other extension, however it got installed.
          ExtensionSettings =
            lib.mapAttrs' (_: id:
              lib.nameValuePair id {
                installation_mode = "normal_installed";
                install_url = "https://addons.mozilla.org/firefox/downloads/latest/${id}/latest.xpi";
              })
            extensions
            // {"*".installation_mode = "blocked";};

          PasswordManagerEnabled = false;
          Preferences."browser.startup.page" = {
            Value = 3;
            Status = "locked";
          };
          SearchEngines.Default = "DuckDuckGo";
        };
      };
    };
  };
}
