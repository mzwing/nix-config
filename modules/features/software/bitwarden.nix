# The vault app. Its SSH agent is wired up by software/ssh, which is what points at the socket this exposes.
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
