{
  mzwing.features."software/wakatime" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    requires = ["darwin/homebrew"];

    # Every WakaTime plugin shells out to this one binary, and downloads its own copy into ~/.wakatime when it is not on PATH.
    packages.home = pkgs: [pkgs.wakatime-cli];

    # The menubar tracker for everything outside an editor.
    darwin.homebrew.casks = ["wakatime"];

    home = {
      config,
      inputs,
      lib,
      pkgs,
      secrets,
      ...
    }: let
      # agenix spells the darwin secrets directory as a command substitution, so the path only resolves inside a shell.
      apiKeyCommand = pkgs.writeShellScript "wakatime-api-key" ''
        exec ${lib.getExe' pkgs.coreutils "cat"} "${config.age.secrets."wakatime-api-key".path}"
      '';
    in {
      imports = [
        inputs.agenix.homeManagerModules.default
      ];

      age.identityPaths = [
        "${config.home.homeDirectory}/.ssh/agenix"
      ];
      age.secrets."wakatime-api-key".file = secrets."wakatime/api-key";

      # Read by wakatime-cli and by every plugin that wraps it. The vault command keeps the key out of the world-readable store.
      home.file.".wakatime.cfg".text = ''
        [settings]
        api_key_vault_cmd = ${apiKeyCommand}
      '';
    };
  };
}
