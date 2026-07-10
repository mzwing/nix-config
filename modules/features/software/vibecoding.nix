{
  mzwing.features."software/vibecoding" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    darwin = {
      homebrew = {
        brews = [
          "cliproxyapiplus"
          "gryph"
        ];
        casks = [
          "antigravity"
        ];
      };
    };

    nixos = {pkgs, ...}: {
      environment.systemPackages = with pkgs; [
        antigravity
        cc-switch
      ];
    };

    home = {
      lib,
      pkgs,
      ...
    }: {
      programs =
        {
          # TODO: complete antigravity-cli configuration
          antigravity-cli = {
            enable = true;
            enableMcpIntegration = true;
          };
          # TODO: complete codex configuration
          codex = {
            enable = true;
            enableMcpIntegration = true;
          };
        }
        // lib.optionalAttrs pkgs.stdenv.isLinux {
          opencode = {
            enable = true;
            extraPackages = with pkgs; [
              rtk
            ];
            web.enable = true;
            enableMcpIntegration = true;
          };
        };
    };
  };
}
