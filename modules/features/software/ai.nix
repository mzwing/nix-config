let
  systemAiPackages = pkgs:
    with pkgs; [
      nur.repos.mzwing.autocli
      nur.repos.mzwing.hfd
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
