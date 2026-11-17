{inputs, ...}: {
  # agent-skills' mkSourceLockProgram hands its script these paths via toString, so they stay outside its closure and the lock fails once a GC drops them. Drop once upstream interpolates them
  perSystem = {
    lib,
    pkgs,
    ...
  }: {
    apps.skills-sources-lock.program = lib.mkForce (pkgs.writeShellApplication {
      name = "skills-sources-lock";
      runtimeInputs = [
        pkgs.bash
        pkgs.coreutils
        pkgs.jq
        pkgs.nix
        pkgs.npins
      ];
      text = ''
        export AGENT_SKILLS_SOURCE_NORMALIZER=${inputs.agent-skills}/lib/eval-source-manifests.nix
        export AGENT_SKILLS_NIXPKGS_LIB=${pkgs.path + "/lib"}
        export AGENT_SKILLS_SOURCE_REGISTRY_LIB=${inputs.agent-skills}/lib/source-registry.nix
        exec bash ${inputs.agent-skills}/scripts/source-lock.sh --manifest-dir data/skills/sources --lock-file data/skills/sources.lock.json "$@"
      '';
    });
  };
}
