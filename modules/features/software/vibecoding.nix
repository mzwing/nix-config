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
          "antigravity-cli"
          "codex-app"
          "codex-plus-plus"
          "kakuku"
        ];
      };
    };

    # home = {pkgs, ...}: {
    #   programs.opencode = {
    #     enable = true;
    #     extraPackages = with pkgs; [
    #       rtk
    #     ];
    #     web.enable = true;
    #     enableMcpIntegration = true;
    #   };
    # };
  };
}
