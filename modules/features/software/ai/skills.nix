{
  mzwing.features."software/ai/skills" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    requires = [
      # game-art's imagegen.py draws through the proxy, found via the session variables below.
      "software/ai/magpie-client"
    ];

    # Discovery only (`skills find`, `skills use`); its mutable lock would fight Home Manager during activation.
    packages.home = pkgs: [pkgs.skills];

    home = {
      config,
      inputs,
      lib,
      ...
    }: let
      gateway = config.mzwing.magpie.gateways.magpie;

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
        else throw "software/ai/skills: cannot derive a static destination for target '${name}' from '${dest}'";
    in {
      imports = [
        inputs.agent-skills.homeManagerModules.default
      ];

      home.sessionVariables =
        {IMAGEGEN_BASE_URL = gateway.baseUrl;}
        // (
          if gateway.keyFile == null
          then {
            # Loopback takes any key.
            IMAGEGEN_API_KEY = "magpie";
          }
          else {IMAGEGEN_API_KEY_FILE = gateway.keyFile;}
        );

      programs.agent-skills = {
        enable = true;

        sources =
          agentLib.sourcesFromLock {
            manifestsDir = ../../../../data/skills/sources;
            lockFile = ../../../../data/skills/sources.lock.json;
          }
          // {
            local = {
              path = ../../../../data/skills/local;
              filter.maxDepth = 1;
            };
          };

        skills.enable = [
          "clarify-code-names"
          "cnb-docs"
          "cnb-pipeline"
          "conventional-commit-message"
          "design-ui"
          "find-code-simplifications"
          "find-skills"
          "game-art"
          "game-dev"
          "improve-codebase"
          "improve-test-suite"
          "refactor-for-simplicity"
          "semver"
          "speak-plainly"
          "write-docs"
        ];

        # pi, omp and dsh all read ~/.agents/skills, so none needs a target of its own.
        # `link` gives each skill its own home.file entry; the default `symlink-tree` would rsync --delete the agents' own plugins away.
        targets = lib.genAttrs (["agents"] ++ lib.optional config.programs.claude-code.enable "claude") (name: {
          enable = true;
          structure = "link";
          dest = staticDest name;
        });
      };
    };
  };
}
