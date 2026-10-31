{
  mzwing.features."software/ai/obelisk" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    requires = ["software/ai/skills"];

    packages.home = pkgs: [pkgs.nur.repos.mzwing.obelisk];

    # Enabled here rather than in software/ai/skills: the skill is useless without this CLI
    home.programs.agent-skills.skills.enable = ["obelisk"];
  };
}
