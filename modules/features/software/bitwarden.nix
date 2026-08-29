# The official vault app. Just the app: the agents are software/keyguard's.
{
  mzwing.features."software/bitwarden" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    darwin = {
      homebrew.masApps."Bitwarden" = 1352778147;
    };

    nixos = {pkgs, ...}: {
      environment.systemPackages = [pkgs.bitwarden-desktop];
    };
  };
}
