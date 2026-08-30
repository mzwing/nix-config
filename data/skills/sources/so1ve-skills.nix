# so1ve keeps his skills inside his nix config, hence the deep subdir.
{
  pin = {
    type = "github";
    owner = "so1ve";
    repo = "nix-config";
    branch = "main";
  };

  subdir = "dotfiles/agents/skills";

  filter.maxDepth = 1;
}
