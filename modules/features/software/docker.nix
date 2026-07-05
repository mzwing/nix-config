{
  mzwing.features."software/docker" = {
    meta.platforms = ["darwin"];

    darwin = {pkgs, ...}: {
      environment.systemPackages = with pkgs; [
        container
      ];
      homebrew.brews = [
        "container-compose"
      ];
      homebrew.casks = [
        "orbstack"
      ];
    };
  };
}
