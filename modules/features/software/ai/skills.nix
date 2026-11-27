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
      inherit (config.mzwing.magpie) gateway;

      agentLib = inputs.agent-skills.lib.agent-skills;

      lockedSources = agentLib.sourcesFromLock {
        manifestsDir = ../../../../data/skills/sources;
        lockFile = ../../../../data/skills/sources.lock.json;
      };

      applyEdits = edits: original:
        lib.foldl' (text: edit:
          if !lib.hasInfix edit.from text
          then throw "software/ai/skills: missing edit anchor '${edit.from}'"
          else if edit ? until
          then let
            parts = lib.splitString edit.from text;
            remainder = lib.concatStringsSep edit.from (builtins.tail parts);
            endParts = lib.splitString edit.until remainder;
          in
            if !lib.hasInfix edit.until remainder
            then throw "software/ai/skills: missing edit anchor '${edit.until}' after '${edit.from}'"
            else builtins.head parts + edit.until + lib.concatStringsSep edit.until (builtins.tail endParts)
          else builtins.replaceStrings [edit.from] [edit.to] text)
        original
        edits;

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
          lockedSources
          // {
            local = {
              path = ../../../../data/skills/local;
              filter.maxDepth = 1;
            };
          };

        skills.enable = [
          "chrome-extensions"
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
          "typescript-dev"
          "write-docs"
        ];

        skills.explicit.modern-web-guidance = {
          from = "modern-web-guidance-skills";
          # `original` is read from a per-system derivation (import-from-derivation), which breaks cross-platform eval in CI
          transform = _:
            applyEdits [
              {
                from = "MANDATORY: Execute FIRST for all HTML/CSS and clientside JS tasks. Do NOT skip — web APIs evolve rapidly and training weights contain obsolete patterns.";
                to = "Use at the start of HTML/CSS and client-side JS tasks; training data lags the web platform.";
              }
              {
                from = "Run `modern-web-guidance` directly with `npx` using a";
                to = "Run `modern-web-guidance` with the commands below, using a";
              }
              {
                from = "npx -y modern-web-guidance@latest";
                to = "nix shell nixpkgs#pnpm nixpkgs#nodejs -c pnpx modern-web-guidance@latest";
              }
              {
                from = "### Step 4. Disclose Skill Usage";
                until = "## Alternative flow";
              }
              {
                from = "## Using npx / pnpx";
                until = "## Guidelines";
              }
            ]
            (builtins.readFile "${lockedSources.modern-web-guidance-skills.path}/${lockedSources.modern-web-guidance-skills.subdir}/modern-web-guidance/SKILL.md");
        };

        # pi and omp read ~/.agents/skills, so neither needs a target of its own.
        # `link` gives each skill its own home.file entry; the default `symlink-tree` would rsync --delete the agents' own plugins away.
        targets =
          lib.genAttrs (["agents"] ++ lib.optional config.programs.claude-code.enable "claude") (name: {
            enable = true;
            structure = "link";
            dest = staticDest name;
          })
          // lib.optionalAttrs config.programs.antigravity-cli.enable {
            antigravity = {
              enable = true;
              structure = "link";
              dest = ".gemini/config/skills";
            };
          };
      };
    };
  };
}
