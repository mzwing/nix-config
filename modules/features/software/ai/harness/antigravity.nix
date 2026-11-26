let
  agentContext = import ../../../../../data/agent-context.nix;
in {
  mzwing.features."software/ai/harness/antigravity" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    requires = ["software/development/wakatime"];

    home = {
      inputs,
      pkgs,
      system,
      ...
    }: let
      rtkPlugin = pkgs.runCommand "agy-rtk-plugin" {nativeBuildInputs = [pkgs.rtk];} ''
        HOME=$TMPDIR rtk init -g --agent antigravity
        cp -r $TMPDIR/.gemini/config/plugins/rtk $out
      '';
      # agy-codemode's bundled rules contradict agentContext.rules
      agyToolPlugins = pkgs.nur.repos.mzwing.agy-tool-plugins.overrideAttrs {
        postInstall = "rm -r $out/agy-codemode/rules";
      };
    in {
      home.file = {
        ".gemini/config/plugins/antigravity-cli-wakatime".source = pkgs.nur.repos.mzwing.antigravity-wakatime;
        ".gemini/config/plugins/rtk".source = rtkPlugin;
        ".gemini/config/plugins/agy-codemode".source = "${agyToolPlugins}/agy-codemode";
        ".gemini/config/plugins/agy-output-guard".source = "${agyToolPlugins}/agy-output-guard";
        ".gemini/config/plugins/agy-rehydrate".source = "${agyToolPlugins}/agy-rehydrate";
      };

      # rtk runs both the plugin's hook and the commands it rewrites
      home.packages = [
        (pkgs.nur.repos.mzwing.antigravity-hub-modified.override {
          antigravity-hub = inputs.llm-agents.packages.${system}.antigravity-hub;
        })
        pkgs.rtk
      ];

      # Only the shared ~/.gemini config, without the CLI itself
      programs.antigravity-cli = {
        enable = true;
        package = null;
        # Antigravity edits mcp_config.json from its UI, so it cannot be a store symlink
        mutableSettings = true;
        enableMcpIntegration = true;
        context.AGENTS = ''
          ${agentContext.rules}
          ${agentContext.delegation}
          ${agentContext.codegraph}
        '';
      };
    };
  };
}
