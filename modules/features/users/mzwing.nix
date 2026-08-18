let
  identities = import ../../../data/identities.nix;
in {
  mzwing.features."users/mzwing" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    darwin = {
      hostname,
      username,
      ...
    }: {
      networking.hostName = hostname;
      networking.computerName = hostname;
      system.defaults.smb.NetBIOSName = hostname;

      users.users.${username} = {
        home = "/Users/${username}";
        description = username;
      };

      system.primaryUser = username;
      nix.settings.trusted-users = [username];
    };

    nixos = {username, ...}: {
      users.users.${username} = {
        isNormalUser = true;
        description = username;
        openssh.authorizedKeys.keys = [
          identities.users.mzwing
        ];
        extraGroups = [
          "wheel"
          "networkmanager"
          "adbusers"
          "kvm"
        ];
      };

      nix.settings.trusted-users = [username];
    };
  };
}
