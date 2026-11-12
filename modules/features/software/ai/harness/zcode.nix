let
  agentContext = import ../../../../../data/agent-context.nix;
in {
  mzwing.features."software/ai/harness/zcode" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    requires = ["darwin/homebrew"];

    darwin.homebrew.casks = ["zcode"];

    home = {
      inputs,
      lib,
      pkgs,
      system,
      ...
    }: {
      imports = [inputs.nur.repos.mzwing.modules.homeManager.zcode];

      programs.zcode = {
        enable = true;
        package = lib.mkIf pkgs.stdenv.hostPlatform.isLinux inputs.llm-agents.packages.${system}.zcode;
        context = ''
          ${agentContext.rules}
          ${agentContext.codegraph}
        '';
        enableMcpIntegration = true;
      };
    };
  };
}
