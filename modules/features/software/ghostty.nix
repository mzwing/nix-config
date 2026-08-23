{
  mzwing.features."software/ghostty" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    # software/shell pulls this in on the servers too, which have no use for a terminal emulator.
    darwin = {
      lib,
      type,
      ...
    }:
      lib.mkIf (type == "desktop") {
        homebrew.casks = ["ghostty"];
      };

    home = {
      lib,
      pkgs,
      type,
      ...
    }:
      lib.mkIf (type == "desktop") {
        programs.ghostty = {
          enable = true;
          package =
            if pkgs.stdenv.hostPlatform.isDarwin
            then null
            else pkgs.ghostty;
          enableFishIntegration = true;
          settings = {
            font-style = "Retina";
            font-size = 17;
            font-family = "JetBrains Mono";
            mouse-hide-while-typing = true;
            cursor-style-blink = true;
            shell-integration-features = "ssh-terminfo,ssh-env";
            background-blur = true;
          };
        };
      };
  };
}
