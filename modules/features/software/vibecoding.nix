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
      ];
    };

    home = {
      lib,
      pkgs,
      ...
    }: {
      programs = {
        antigravity-cli = {
          enable = true;
          enableMcpIntegration = true;
        };
        codex = {
          enable = true;
          enableMcpIntegration = true;
        };
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
