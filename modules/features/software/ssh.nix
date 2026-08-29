# The SSH client, and whichever agent holds the keys. Which agent follows from the host's role rather than its platform: a desktop has Keyguard running and unlocked, a server has no vault and no GUI to unlock one with.
let
  # Not a sandbox at work: the app just takes a group container as a conventional place to bind a socket.
  keyguardSocket = home: "${home}/Library/Group Containers/com.artemchep.keyguard/ssh-agent.sock";
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
      # Nothing else provides that socket, so a desktop selecting this has to select software/keyguard too.
      viaKeyguard = type == "desktop";

      socket = keyguardSocket config.home.homeDirectory;
    in {
      # Whoever owns SSH_AUTH_SOCK owns SSH auth, and gpg-agent's fish integration exports its own. Only one of them gets to.
      services.gpg-agent.enableSshSupport = !viaKeyguard;

      home.sessionVariables = lib.optionalAttrs viaKeyguard {
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
        settings = lib.optionalAttrs viaKeyguard {
          "*" = {
            # Quoted, because "Group Containers" has a space in it and ssh_config splits on whitespace.
            IdentityAgent = ''"${socket}"'';
            # No key files left to cache, and the agent only signs; it takes no additions.
            AddKeysToAgent = false;
          };
        };
      };
    };
  };
}
