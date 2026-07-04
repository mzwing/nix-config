{
  mzwing.features."software/shell" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    darwin = {
      pkgs,
      username,
      ...
    }: {
      programs.fish.enable = true;
      environment.shells = [pkgs.fish];
      users.users.${username}.shell = pkgs.fish;
    };

    nixos = {
      pkgs,
      username,
      ...
    }: {
      programs.fish.enable = true;
      users.users.${username}.shell = pkgs.fish;
    };

    home = {pkgs, ...}: {
      home.packages = [pkgs.any-nix-shell];
      home.shellAliases = {
        urldecode = "python3 -c 'import sys, urllib.parse as ul; print(ul.unquote_plus(sys.stdin.read()))'";
        urlencode = "python3 -c 'import sys, urllib.parse as ul; print(ul.quote_plus(sys.stdin.read()))'";
      };
    };
  };
}
