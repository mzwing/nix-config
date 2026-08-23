# Agent skills: the pinned sources, what is built from them, and where they land.
{
  mzwing.features."software/skills" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    home = {
      inputs,
      lib,
      pkgs,
      ...
    }: let
      agentLib = inputs.agent-skills.lib.agent-skills;

      # `structure = "link"` needs a literal path under $HOME, but upstream's dests are shell expressions and its own extraction only handles the `${VAR:-$HOME/...}` form, not pi's plain `$HOME/...`.
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
      imports = [inputs.agent-skills.homeManagerModules.default];

      # Discovery only (`skills find`, `skills use`); its mutable lock would fight Home Manager during activation.
      home.packages = [pkgs.skills];

      programs.agent-skills = {
        enable = true;

        sources = agentLib.sourcesFromLock {
          manifestsDir = ../../../data/skills/sources;
          lockFile = ../../../data/skills/sources.lock.json;
        };

        skills.enable = [
          "find-skills"
          "refactor-for-simplicity"
        ];

        # `link` gives each skill its own home.file entry; the default `symlink-tree` would rsync --delete the agents' own plugins away.
        targets =
          lib.genAttrs [
            "claude"
            "pi"
          ] (name: {
            enable = true;
            structure = "link";
            dest = staticDest name;
          });
      };
    };
  };
}
