{
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
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDfanSYN5epQylG/y/stltpjwDr2IX+TmT7ekhwaJ7nVy5Xr/6NYifudALQ7jrJYLD5fSIB6fp0d6WbSf2w7anHRD+re85IyD2BVscUtNPrbdv2xMARrqsThbzGyumBRCCz9ppOojeUuaOy94NTwlx/fRcQ2nTB7WlfSEEfVsgI+odBYoTa8braC93rXAE/CVV5jwYhuQN7huWARGjNVDVtQLdFg+cVHg+2KF3oAFd+wHF8QEqWucmJJIt8oL0CvSYDAOOHrqaIdv5tGUXOa+dxtrUiWpXQVNKC6EomqmmGK4dPe2GVHJjMaVHzYIOIZEIcuEm+sF8M2EL903XLvJ8aPN4+EfYGVF4fPk8Y9qnOqOXxZaRqW13+l28q6Wav1EyFKeEleXpH+rrPrFTI561GDgISFtJBZ1qsdWBWb6ivx7+Qri2ZIRM5A1Q4xNNmWnH+ST5zaKI6CVfwmb1Kr4DfWm8z2fdNZzzmPJnM1wItssmA4Nn/jL5mmF+Y1mec0EM= lockinwise lolite@MZWING-PC"
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
