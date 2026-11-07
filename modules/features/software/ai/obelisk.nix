{
  mzwing.features."software/ai/obelisk" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    requires = ["software/ai/skills"];

    packages.home = pkgs: [pkgs.nur.repos.mzwing.obelisk];

    home = {
      config,
      lib,
      ...
    }: {
      # Enabled here rather than in software/ai/skills: the skill is useless without this CLI
      programs.agent-skills.skills.enable = ["obelisk"];

      home.file.".omp/agent/rules/obelisk.md" = lib.mkIf (config.programs ? omp) {
        source = ../../../../data/omp/rules/obelisk.md;
      };
    };
  };
}
