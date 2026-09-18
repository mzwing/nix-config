{
  mzwing.features."software/paseo" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    requires = ["darwin/homebrew"];

    darwin.homebrew.casks = ["paseo"];

    nixos = {inputs, ...}: {
      imports = [inputs.paseo.nixosModules.paseo];

      services.paseo.enable = true;
    };
  };
}
