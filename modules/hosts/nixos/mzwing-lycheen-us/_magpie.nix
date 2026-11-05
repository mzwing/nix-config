{
  # magpie sizes this as 128 MiB a Claude Code, which would be 28 here, but a run replaying a long conversation peaks at 250–450 MiB
  services.magpie.settings.claudeRunsMost = 8;
}
