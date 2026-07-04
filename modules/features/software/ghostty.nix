{
  mzwing.features."software/ghostty" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    darwin = {
      homebrew.casks = ["ghostty"];
    };

    home = {pkgs, ...}: {
      programs.ghostty = {
        enable = true;
        package =
          if pkgs.stdenv.isDarwin
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
