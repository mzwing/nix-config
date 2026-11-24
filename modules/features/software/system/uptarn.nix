{
  mzwing.features."software/system/uptarn" = {
    meta.platforms = ["nixos"];

    nixos = {
      config,
      hostname,
      inputs,
      lib,
      secrets,
      ...
    }: {
      imports = [inputs.uptarn.nixosModules.agent];

      age.secrets = {
        uptarn-token.file = secrets."${lib.removePrefix "mzwing-" hostname}/uptarn/token";
        uptarn-enroll-token.file = secrets."uptarn/enroll-token";
      };

      services.uptarn-agent = {
        enable = true;
        hubUrl = "https://status.service.mzwing.eu.org";
        tokenFile = config.age.secrets.uptarn-token.path;
        enrollTokenFile = config.age.secrets.uptarn-enroll-token.path;
        settings.mounts = [
          {
            path = "/";
            label = "root";
          }
        ];
      };
    };
  };
}
