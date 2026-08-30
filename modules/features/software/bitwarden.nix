{
  mzwing.features."software/bitwarden" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    requires = ["darwin/homebrew"];

    packages.nixos = pkgs: [pkgs.bitwarden-desktop];

    darwin.homebrew.masApps."Bitwarden" = 1352778147;
  };
}
