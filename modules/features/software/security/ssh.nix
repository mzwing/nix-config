let
  # Triwarden is macOS-only, so Linux desktops keep Bitwarden's agent.
  vaultSocket = pkgs: home:
    if pkgs.stdenv.hostPlatform.isDarwin
    then "${home}/Library/Group Containers/FX3VR69P5K.io.github.sinhong2011.triwarden/agent.sock"
    else "${home}/.bitwarden-ssh-agent.sock";
in {
  mzwing.features."software/security/ssh" = {
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
      viaVault = type == "desktop";

      socket = vaultSocket pkgs config.home.homeDirectory;
    in {
      services.gpg-agent.enableSshSupport = !viaVault;

      home.sessionVariables = lib.optionalAttrs viaVault {
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

        settings = lib.optionalAttrs viaVault {
          "*" = {
            # Home Manager writes values unquoted, and the macOS path has a space.
            IdentityAgent = ''"${socket}"'';
            AddKeysToAgent = false;
          };
        };
      };
    };
  };
}
