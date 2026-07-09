{
  mzwing.features."software/zed-editor" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    darwin = {
      homebrew.casks = ["zed"];
    };

    # TODO: complete zed-editor configuration
    home = {
      inputs,
      lib,
      pkgs,
      ...
    }: let
      typenix = inputs.typenix.packages.${pkgs.stdenv.hostPlatform.system}.default;
    in {
      programs.zed-editor = {
        enable = true;
        package =
          if pkgs.stdenv.isDarwin
          then null
          else pkgs.zed-editor;
        extraPackages = lib.optionals (!pkgs.stdenv.isDarwin) [
          pkgs.alejandra
          pkgs.nixd
          typenix
        ];
        extensions = [
          "nix"
        ];
        userTasks = [
          {
            label = "typenix: check";
            command = "${typenix}/bin/typenix";
            args = ["--noEmit"];
          }
        ];
        enableMcpIntegration = true;
        installRemoteServer =
          if pkgs.stdenv.isDarwin
          then false
          else true;
      };
    };
  };
}
