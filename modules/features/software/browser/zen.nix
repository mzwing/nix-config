{
  mzwing.features."software/browser/zen" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    requires = ["darwin/homebrew"];

    darwin.homebrew.casks = ["zen"];

    home = {
      inputs,
      lib,
      pkgs,
      ...
    }: let
      inherit (pkgs.stdenv.hostPlatform) isDarwin;
      extensions = lib.importJSON ../../../../data/zen/extensions.json;
    in {
      imports = [
        inputs.zen-browser.homeModules.beta
      ];

      programs.zen-browser = {
        enable = true;
        # The cask installs it on darwin.
        package = lib.mkIf isDarwin null;

        policies = {
          # Homebrew leaves a self-updating cask alone, so Zen has to update itself there.
          DisableAppUpdate = lib.mkIf isDarwin false;

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
