let
  systemAiPackages = pkgs:
    with pkgs; [
      defuddle
    ];
in {
  mzwing.features."software/ai" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    darwin = {pkgs, ...}: {
      environment.systemPackages =
        systemAiPackages pkgs;
      homebrew = {
        brews = [
          "hfd"
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

    # TODO: sync hfd & manboster & kelivo, add custom llama.cpp build
    nixos = {pkgs, ...}: {
      environment.systemPackages =
        systemAiPackages pkgs
        ++ (with pkgs; [
          llama-cpp
          stable-diffusion-cpp-cuda
        ]);
    };
  };
}
