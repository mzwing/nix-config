{
  mzwing.features."software/zed-editor" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    requires = ["darwin/homebrew"];

    darwin = {
      homebrew.casks = ["zed"];
    };

    # TODO: complete zed-editor configuration
    home = {
      inputs,
      lib,
      pkgs,
      ...
    }: {
      programs.zed-editor = {
        enable = true;
        package =
          if pkgs.stdenv.hostPlatform.isDarwin
          then null
          else pkgs.zed-editor;
        extraPackages = lib.optionals (!pkgs.stdenv.hostPlatform.isDarwin) [
          pkgs.alejandra
          pkgs.nixd
          pkgs.nur.repos.mzwing.typenix
        ];
        extensions = [
          "nix"
        ];
        userTasks = [
          {
            label = "typenix: check";
            command = "typenix";
            args = ["--noEmit"];
          }
        ];
        enableMcpIntegration = true;
        installRemoteServer = !pkgs.stdenv.hostPlatform.isDarwin;
      };
    };
  };
}
