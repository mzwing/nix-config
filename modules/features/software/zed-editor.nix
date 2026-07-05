{
  mzwing.features."software/zed-editor" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    darwin = {
      homebrew.casks = ["zed"];
    };

    home = {pkgs, ...}: {
      programs.zed-editor = {
        enable = true;
        package =
          if pkgs.stdenv.isDarwin
          then null
          else pkgs.zed-editor;
        enableMcpIntegration = true;
        installRemoteServer =
          if pkgs.stdenv.isDarwin
          then false
          else true;
      };
    };
  };
}
