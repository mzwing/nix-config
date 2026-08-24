# The SSH client, and whichever agent holds the keys. Which agent follows from the host's role rather than its platform: a desktop has Bitwarden running and unlocked, a server has no vault and no GUI to unlock one with.
let
  # The App Store build is sandboxed, so its socket sits inside the container rather than at the usual ~/.bitwarden-ssh-agent.sock.
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
      # Nothing else provides that socket, so a desktop selecting this has to select software/bitwarden too.
      viaBitwarden = type == "desktop";

      socket = bitwardenSocket pkgs config.home.homeDirectory;
    in {
      # Whoever owns SSH_AUTH_SOCK owns SSH auth, and gpg-agent's fish integration exports its own. Only one of them gets to.
      services.gpg-agent.enableSshSupport = !viaBitwarden;

      home.sessionVariables = lib.optionalAttrs viaBitwarden {
        SSH_AUTH_SOCK = socket;
      };

      programs.ssh = {
        enable = true;

        # Home Manager's own `Host *` block is on its way out and warns if left on. Everything it set was already ssh's own default, so there is nothing to carry over.
        enableDefaultConfig = false;

        # Rendered as the first line, ahead of every Host block — the only place OrbStack's include works.
        includes =
          lib.optional pkgs.stdenv.hostPlatform.isDarwin "${config.home.homeDirectory}/.orbstack/ssh/config"
          ++ ["${config.home.homeDirectory}/.ssh/config.d/*"];

        # SSH_AUTH_SOCK never reaches GUI clients, which see no login shell. This does.
        settings = lib.optionalAttrs viaBitwarden {
          "*" = {
            IdentityAgent = socket;
            # No key files left to cache, and the agent only signs; it takes no additions.
            AddKeysToAgent = false;
          };
        };
      };
    };
  };
}
