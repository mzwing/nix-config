# Only cnb-docs: cnb-pipeline lives rewritten in data/skills/local, and a second copy here would clash with it.
{
  pin = {
    type = "git";
    url = "https://cnb.cool/cnb/skills/cnb-skill.git";
    forge = "none";
    branch = "main";
  };

  subdir = "skills";

  filter = {
    maxDepth = 1;
    nameRegex = "cnb-docs";
  };
}
