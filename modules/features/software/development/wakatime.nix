{
  mzwing.features."software/development/wakatime" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    requires = [
      "darwin/homebrew"
      "home/agenix"
    ];

    # Every WakaTime plugin shells out to this one binary, and downloads its own copy into ~/.wakatime when it is not on PATH.
    packages.home = pkgs: [pkgs.wakatime-cli];

    # A server's user cannot read its host key, so there the system decrypts the key for them.
    nixos = {
      lib,
      secrets,
      type,
      username,
      ...
    }: {
      age.secrets.wakatime-api-key = lib.mkIf (type == "server") {
        file = secrets."wakatime/api-key";
        owner = username;
      };
    };

    home = {
      config,
      lib,
      osConfig,
      pkgs,
      secrets,
      type,
      ...
    }: let
      keyPath =
        if type == "server"
        then osConfig.age.secrets.wakatime-api-key.path
        else config.age.secrets.wakatime-api-key.path;

      # agenix spells the darwin secrets directory as a command substitution, so the path only resolves inside a shell.
      apiKeyCommand = pkgs.writeShellScript "wakatime-api-key" ''
        exec ${lib.getExe' pkgs.coreutils "cat"} "${keyPath}"
      '';
    in {
      age.secrets.wakatime-api-key = lib.mkIf (type != "server") {
        file = secrets."wakatime/api-key";
      };

      # Read by wakatime-cli and by every plugin that wraps it. The vault command keeps the key out of the world-readable store.
      home.file.".wakatime.cfg".text = ''
        [settings]
        api_key_vault_cmd = ${apiKeyCommand}
      '';
    };
  };
}
