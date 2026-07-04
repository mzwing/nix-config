{
  mzwing.features."ui/fonts" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    darwin = {pkgs, ...}: {
      fonts.packages = with pkgs; [
        material-design-icons
        font-awesome
        nerd-fonts.symbols-only
        nerd-fonts.fira-code
        nerd-fonts.jetbrains-mono
        nerd-fonts.iosevka
      ];
    };

    nixos = {pkgs, ...}: {
      fonts.packages = with pkgs; [
        material-design-icons
        font-awesome
        nerd-fonts.symbols-only
        nerd-fonts.fira-code
        nerd-fonts.jetbrains-mono
        nerd-fonts.iosevka
      ];
    };
  };
}
