{
  mzwing.features."software/gryph" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    home = {inputs, ...}: {
      imports = [inputs.nur.repos.mzwing.modules.homeManager.gryph];

      programs.gryph = {
        enable = true;
        settings.storage.retention_days = 30;
      };
    };
  };
}
