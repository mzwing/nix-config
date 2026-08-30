let
  # The App Store build is sandboxed, so its socket sits inside the container.
  bitwardenSocket = pkgs: home:
    if pkgs.stdenv.hostPlatform.isDarwin
    then "${home}/Library/Containers/com.bitwarden.desktop/Data/.bitwarden-ssh-agent.sock"
    else "${home}/.bitwarden-ssh-agent.sock";
in {
  mzwing.features."software/ssh" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    home = {
      config,
      lib,
      pkgs,
      type,
      ...
    }: let
      viaBitwarden = type == "desktop";

      socket = bitwardenSocket pkgs config.home.homeDirectory;
    in {
      services.gpg-agent.enableSshSupport = !viaBitwarden;

      home.sessionVariables = lib.optionalAttrs viaBitwarden {
        SSH_AUTH_SOCK = socket;
      };

      programs.ssh = {
        enable = true;

        # Home Manager's own `Host *` block warns if left on, and only set ssh's own defaults.
        enableDefaultConfig = false;

        # First line, ahead of every Host block — the only place OrbStack's include works.
        includes =
          lib.optional pkgs.stdenv.hostPlatform.isDarwin "${config.home.homeDirectory}/.orbstack/ssh/config"
          ++ ["${config.home.homeDirectory}/.ssh/config.d/*"];

        settings = lib.optionalAttrs viaBitwarden {
          "*" = {
            IdentityAgent = socket;
            AddKeysToAgent = false;
          };
        };
      };
    };
  };
}
