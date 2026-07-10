{
  mzwing.features."flatpak" = {
    meta.platforms = ["nixos"];

    nixos = {inputs, ...}: {
      imports = [inputs.flatpaks.nixosModules.default];

      services.flatpak = {
        enable = true;
        remotes.flathub = "https://dl.flathub.org/repo/flathub.flatpakrepo";
      };
    };
  };
}
