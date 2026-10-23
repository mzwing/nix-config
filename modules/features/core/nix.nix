{lib, ...}: let
  cacheData = import ../../../data/caches.nix;

  nurCaches = map (entry: entry.cache) (lib.attrValues cacheData.nur);

  nixOptions = {
    mirrorSubstituters = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Nearby mirrors, ahead of every other layer. Set by network/china-mirrors.";
    };

    extraSubstituters = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = cacheData.extraSubstituters;
      description = "Substituters after the public caches, before the NUR ones.";
    };

    unreachableSubstituters = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Substituters this host cannot reach, dropped from every layer.";
    };
  };
in {
  mzwing.features."core/nix" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    requires = ["core/overlays"];

    system = {
      config,
      lib,
      system,
      ...
    }: {
      options.mzwing.nix = nixOptions;

      config = {
        nix = {
          settings = {
            experimental-features = [
              "nix-command"
              "flakes"
            ];

            substituters = lib.mkForce (
              lib.subtractLists config.mzwing.nix.unreachableSubstituters (
                config.mzwing.nix.mirrorSubstituters
                ++ cacheData.defaultSubstituters
                # Caches rank by the priority they advertise (numtide 30, cuda 50) before list position; pin these to the cachix caches' 41.
                ++ map (url: "${url}?priority=41") config.mzwing.nix.extraSubstituters
                ++ map (cache: cache.url) nurCaches
              )
            );

            # trusted-public-keys rather than the extra- form: nixos-anywhere seeds the installer from this exact setting, and never reads the other one.
            trusted-public-keys = lib.unique (
              cacheData.defaultPublicKeys
              ++ cacheData.extraPublicKeys
              ++ map (cache: cache.publicKey) nurCaches
            );

            builders-use-substitutes = true;
          };

          gc = {
            automatic = lib.mkDefault true;
            options = lib.mkDefault "--delete-older-than 3d";
          };
        };

        nixpkgs = {
          hostPlatform = lib.mkDefault system;
          config.allowUnfree = true;
        };
      };
    };

    darwin = {pkgs, ...}: {
      nix = {
        enable = true;
        package = pkgs.nix;
        settings.auto-optimise-store = false;
      };

      nixpkgs.config.android_sdk.accept_license = true;
    };

    nixos = {lib, ...}: {
      nix = {
        channel.enable = false;
        gc.dates = lib.mkDefault "weekly";
      };

      system.stateVersion = "26.11";
    };
  };
}
