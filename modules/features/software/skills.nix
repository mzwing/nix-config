let
  endpoint = import ../../../data/cliproxyapiplus.nix;
in {
  mzwing.features."software/skills" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    requires = [
      # game-art's imagegen.py draws through the proxy, found via the session variables below.
      "software/cliproxyapiplus"
    ];

    # Discovery only (`skills find`, `skills use`); its mutable lock would fight Home Manager during activation.
    packages.home = pkgs: [pkgs.skills];

    home = {
      config,
      inputs,
      lib,
      secrets,
      ...
    }: let
      agentLib = inputs.agent-skills.lib.agent-skills;

      # `structure = "link"` needs a literal path under $HOME, but upstream's dests are shell expressions and its own extraction only handles the `${VAR:-$HOME/...}` form, not the plain `$HOME/...` that agents uses.
      staticDest = name: let
        dest = agentLib.defaultTargets.${name}.dest;
        # Brackets rather than backslashes: builtins.match is POSIX ERE, where \{ and \} are undefined — glibc rejects them outright, so \$\{...\} evaluated on macOS but blew up on Linux.
        expanded = builtins.match "[$][{][^}]*:-[$]HOME/([^}]+)[}](.*)" dest;
        plain = builtins.match "[$]HOME/(.*)" dest;
      in
        if expanded != null
        then (builtins.elemAt expanded 0) + (builtins.elemAt expanded 1)
        else if plain != null
        then builtins.elemAt plain 0
        else throw "software/skills: cannot derive a static destination for target '${name}' from '${dest}'";
    in {
      imports = [
        inputs.agenix.homeManagerModules.default
        inputs.agent-skills.homeManagerModules.default
      ];

      # Home Manager is a separate agenix instance, so it cannot read the service's copy of the secret.
      age.identityPaths = [
        "${config.home.homeDirectory}/.ssh/agenix"
      ];
      age.secrets."cliproxyapiplus-api-key".file = secrets."cliproxyapiplus/api-key";

      home.sessionVariables = {
        IMAGEGEN_BASE_URL = endpoint.baseUrl;
        IMAGEGEN_API_KEY_FILE = config.age.secrets."cliproxyapiplus-api-key".path;
      };

      programs.agent-skills = {
        enable = true;

        sources =
          agentLib.sourcesFromLock {
            manifestsDir = ../../../data/skills/sources;
            lockFile = ../../../data/skills/sources.lock.json;
          }
          // {
            local = {
              path = ../../../data/skills/local;
              filter.maxDepth = 1;
            };
          };

        skills.enable = [
          "design-ui"
          "find-code-simplifications"
          "find-skills"
          "game-art"
          "game-dev"
          "refactor-for-simplicity"
          "write-docs"
        ];

        # pi and omp both read ~/.agents/skills, so neither needs a target of its own.
        # `link` gives each skill its own home.file entry; the default `symlink-tree` would rsync --delete the agents' own plugins away.
        targets =
          lib.genAttrs [
            "agents"
            "claude"
          ] (name: {
            enable = true;
            structure = "link";
            dest = staticDest name;
          });
      };
    };
  };
}
