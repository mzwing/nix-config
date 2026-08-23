# One skill source. The filename is the source name; `just skills-update` resolves it into ../sources.lock.json.
{
  pin = {
    type = "github";
    owner = "vercel-labs";
    repo = "skills";
    # Tracked, not followed: the branch only decides what the next `just skills-update` resolves to.
    branch = "main";
  };

  subdir = "skills";

  # One directory per skill, so depth 1 finds them all without descending into a skill's own files.
  filter.maxDepth = 1;
}
