{
  mzwing.features."software/ai" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    requires = ["darwin/homebrew"];

    packages = {
      system = pkgs:
        with pkgs; [
          nur.repos.mzwing.autocli
          nur.repos.mzwing.hfd
          defuddle
        ];

      nixos = pkgs:
        with pkgs; [
          llama-cpp
          stable-diffusion-cpp-cuda
        ];
    };

    darwin.homebrew = {
      brews = [
        "llama.cpp"
        {
          name = "manboster@rc";
          link = true;
        }
        "stable-diffusion.cpp"
      ];
      casks = [
        "kelivo"
      ];
    };
  };
}
