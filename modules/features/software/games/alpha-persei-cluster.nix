{
  mzwing.features."software/games/alpha-persei-cluster" = {
    meta.platforms = ["nixos"];

    nixos = {inputs, ...}: {
      imports = [inputs.alpha-persei-cluster.nixosModules.default];

      services.alpha-persei-cluster.enable = true;
    };
  };
}
