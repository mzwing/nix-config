{
  mzwing.features."software/browser" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    darwin.homebrew = {
      casks = [
        "arc"
        "bewlycat"
        "ungoogled-chromium"
        "zen"
      ];
      masApps = {
        "uBlock Origin Lite" = 6745342698;
        "Userscripts" = 1463298887;
      };
    };

    # TODO: complete chromium configuration
    nixos = {pkgs, ...}: {
      environment.systemPackages = with pkgs; [
        ungoogled-chromium
      ];
    };

    home = {
      inputs,
      lib,
      system,
      ...
    }:
      lib.optionalAttrs (lib.hasSuffix "-linux" system) {
        imports = [
          inputs.zen-browser.homeModules.beta
        ];

        programs.zen-browser.enable = true;
      };
  };
}
