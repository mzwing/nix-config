{
  mzwing.features."software/email" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    requires = ["darwin/homebrew"];

    packages.system = pkgs: [pkgs.hydroxide];

    darwin.homebrew.casks = [
      "thunderbird"
    ];

    nixos.programs.thunderbird.enable = true;
  };
}
