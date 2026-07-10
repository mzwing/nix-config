{
  mzwing.features."nixos/server/digitalocean" = {
    meta.platforms = ["nixos"];

    nixos = {modulesPath, ...}: {
      imports = [
        (modulesPath + "/virtualisation/digital-ocean-config.nix")
      ];
    };
  };
}
