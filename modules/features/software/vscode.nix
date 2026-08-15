{
  mzwing.features."software/vscode" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    darwin = {
      homebrew.casks = ["visual-studio-code"];
    };

    # TODO: complete vscode & vscodium configuration
    home = {
      lib,
      pkgs,
      ...
    }: {
      programs =
        lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
          vscode = {
            enable = true;
            package = null;
          };
        }
        // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
          vscodium = {
            enable = true;
            package = pkgs.vscodium-fhs;
          };
        };
    };
  };
}
