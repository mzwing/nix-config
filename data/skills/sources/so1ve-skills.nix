# so1ve keeps his skills inside his nix config, hence the deep subdir.
{
  pin = {
    type = "github";
    owner = "so1ve";
    repo = "nix-config";
    # Tracked, not followed: the branch only decides what the next `just skills-update` resolves to.
    branch = "main";
  };

  subdir = "dotfiles/agents/skills";

  # One directory per skill, so depth 1 finds them all without descending into a skill's own files.
  filter.maxDepth = 1;
}
