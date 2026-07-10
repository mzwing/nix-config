{
  mzwing.features."nixos/server/ssh" = {
    meta.platforms = ["nixos"];

    nixos = {
      services.openssh = {
        enable = true;
        settings.PasswordAuthentication = false;
      };
    };
  };
}
