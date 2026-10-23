# so1ve keeps his skills inside his nix config, hence the deep subdir.
{
  pin = {
    type = "github";
    owner = "so1ve";
    repo = "nix-config";
    branch = "main";
  };

  subdir = "dotfiles/agents/skills";

  # Only what we enable: so1ve's design-ui is a different skill that would clash with ours in data/skills/local.
  filter = {
    maxDepth = 1;
    nameRegex = "clarify-code-names|improve-codebase|improve-test-suite|refactor-for-simplicity|speak-plainly";
  };
}
