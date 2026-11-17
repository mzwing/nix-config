let
  agentContext = import ../../../../../data/agent-context.nix;
in {
  mzwing.features."software/ai/harness/antigravity-cli" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    requires = ["software/development/wakatime"];

    home = {
      inputs,
      lib,
      pkgs,
      system,
      ...
    }: let
      jsonFormat = pkgs.formats.json {};
      rtkPlugin = pkgs.runCommand "agy-rtk-plugin" {nativeBuildInputs = [pkgs.rtk];} ''
        HOME=$TMPDIR rtk init -g --agent antigravity
        cp -r $TMPDIR/.gemini/config/plugins/rtk $out
      '';
    in {
      home.file = {
        ".gemini/config/plugins/antigravity-cli-wakatime".source = pkgs.nur.repos.mzwing.antigravity-wakatime;
        ".gemini/config/plugins/rtk".source = rtkPlugin;
        ".gemini/antigravity-cli/plugins/agy-hud/config.json".source = jsonFormat.generate "agy-hud-config.json" {
          language = "zh-Hans";
          lineLayout = "expanded";
          display = {
            showTools = true;
            showSkills = true;
            showMcpActivity = true;
            showAgents = true;
            showTodos = true;

            showSessionName = true;
            showSessionTokens = true;
            showDuration = true;
            showEffortLevel = true;
            showOutputStyle = true;

            showCost = true;
            showSpeed = true;
            showConfigCounts = true;

            showAntigravityVersion = true;
            showMemoryUsage = true;
            showPromptCache = true;

            showAgentState = true;
            showExecutionMode = true;
            showSandbox = true;
            showArtifacts = true;
            showTaskCount = true;
            showPendingInput = true;
            showToolConfirmation = true;
            showPlanTier = true;
          };
        };
      };

      programs.antigravity-cli = {
        enable = true;
        package = let
          agy = pkgs.nur.repos.mzwing.antigravity-cli-modified.override {
            antigravity-cli = inputs.llm-agents.packages.${system}.antigravity-cli;
          };
        in
          pkgs.symlinkJoin {
            name = "agy-wrapped-${agy.version}";
            paths = [agy];
            nativeBuildInputs = [pkgs.makeWrapper];
            # The self-updater would replace the pinned binary; rtk runs both the hook and the commands it rewrites
            postBuild = ''
              wrapProgram $out/bin/agy \
                --set AGY_CLI_DISABLE_AUTO_UPDATE true \
                --prefix PATH : ${lib.makeBinPath [pkgs.rtk]}
            '';
          };
        # agy rewrites settings.json at startup, so it cannot be a store symlink
        mutableSettings = true;
        enableMcpIntegration = true;
        context.AGENTS = ''
          ${agentContext.rules}
          ${agentContext.codegraph}
        '';
        # agy checks permissions after rtk's hook has rewritten `git push` to `rtk git push`
        permissions.deny = lib.concatMap (cmd: ["command(${cmd})" "command(rtk ${cmd})" "command(rtk bypass ${cmd})"]) ["git commit" "git push"];
        settings = {
          agentMode = "auto";
          altScreenMode = "always";
          enableTerminalSandbox = true;
          contextWindow = "";
          statusLine = {
            type = "command";
            command = lib.getExe pkgs.nur.repos.mzwing.agy-hud;
            stack_with_default = false;
          };
        };
      };
    };
  };
}
