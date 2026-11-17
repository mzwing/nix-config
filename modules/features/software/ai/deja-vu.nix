{
  mzwing.features."software/ai/deja-vu" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    requires = [
      "software/ai/mcp"
      "software/ai/skills"
    ];

    home = {
      config,
      inputs,
      lib,
      system,
      ...
    }: let
      deja-vu = inputs.llm-agents.packages.${system}.deja-vu;
    in {
      home.packages = [deja-vu];

      home.sessionVariables.DEJA_NO_UPDATE_NOTICE = "1";

      programs.mcp.servers.deja = {
        command = lib.getExe deja-vu;
        args = ["mcp"];
        env.DEJA_NO_UPDATE_NOTICE = "1";
      };

      # Enabled here rather than in software/ai/skills: the skill is useless without this CLI
      programs.agent-skills.skills.enable = ["deja-search"];

      home.file.".omp/agent/rules/deja-vu.md" = lib.mkIf (config.programs ? omp) {
        source = ../../../../data/omp/rules/deja-vu.md;
      };
    };
  };
}
