{
  config,
  lib,
  ...
}: let
  cacheData = import ../../../data/caches.nix;

  # `config` here is the flake-parts config; the submodules below shadow it.
  nurCaches = map (entry: entry.cache) (builtins.attrValues config.mzwing.registry.nur);
  nurSubstituters = map (cache: cache.url) nurCaches;
  nurPublicKeys = map (cache: cache.publicKey) nurCaches;

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
  };

  # Shared by both platforms so they cannot drift apart again.
  mkNixSettings = hostConfig: {
    experimental-features = [
      "nix-command"
      "flakes"
    ];

    substituters = lib.mkForce (
      hostConfig.mzwing.nix.mirrorSubstituters
      ++ cacheData.defaultSubstituters
      ++ hostConfig.mzwing.nix.extraSubstituters
      ++ nurSubstituters
    );

    extra-trusted-public-keys = lib.unique (
      cacheData.defaultPublicKeys
      ++ cacheData.extraPublicKeys
      ++ nurPublicKeys
    );

    builders-use-substitutes = true;
  };
in {
  mzwing.features."core/nix" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    darwin = {
      config,
      inputs,
      lib,
      pkgs,
      system,
      ...
    }: {
      options.mzwing.nix = nixOptions;

      config = {
        nix = {
          enable = true;
          package = pkgs.nix;

          settings =
            mkNixSettings config
            // {
              auto-optimise-store = false;
            };

          gc = {
            automatic = lib.mkDefault true;
            options = lib.mkDefault "--delete-older-than 3d";
          };
        };

        nixpkgs = {
          hostPlatform = lib.mkDefault system;
          config = {
            allowUnfree = true;
            android_sdk.accept_license = true;
          };
          overlays = [inputs.nur.overlays.default];
        };
      };
    };

    nixos = {
      config,
      inputs,
      lib,
      system,
      ...
    }: {
      options.mzwing.nix = nixOptions;

      config = {
        nix = {
          channel.enable = false;

          settings = mkNixSettings config;

          gc = {
            automatic = lib.mkDefault true;
            dates = lib.mkDefault "weekly";
            options = lib.mkDefault "--delete-older-than 3d";
          };
        };

        nixpkgs = {
          hostPlatform = lib.mkDefault system;
          config.allowUnfree = true;
          overlays = [inputs.nur.overlays.default];
        };

        system.stateVersion = "26.11";
      };
    };
  };
}
