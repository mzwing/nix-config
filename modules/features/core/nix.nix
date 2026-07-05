let
  defaultSubstituters = [
    "https://cache.nixos.org"
    "https://nix-community.cachix.org"
  ];
  nixCommunityKey = "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=";
  nixOptions = lib: {
    extraSubstitutersBeforeDefault = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Extra substituters placed before cache.nixos.org and nix-community caches.";
    };
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
      options.mzwing.nix = nixOptions lib;

      config = {
        nix = {
          enable = true;
          package = pkgs.nix;

          settings = {
            experimental-features = [
              "nix-command"
              "flakes"
            ];
            substituters = lib.mkForce (
              config.mzwing.nix.extraSubstitutersBeforeDefault
              ++ defaultSubstituters
            );
            extra-trusted-public-keys = [nixCommunityKey];
            builders-use-substitutes = true;
            auto-optimise-store = false;
          };

          gc = {
            automatic = lib.mkDefault true;
            options = lib.mkDefault "--delete-older-than 3d";
          };
        };

        nixpkgs = {
          hostPlatform = lib.mkDefault system;
          config.allowUnfree = true;
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
      options.mzwing.nix = nixOptions lib;

      config = {
        nix = {
          channel.enable = false;
          settings = {
            experimental-features = [
              "nix-command"
              "flakes"
            ];
            substituters = lib.mkForce (
              config.mzwing.nix.extraSubstitutersBeforeDefault
              ++ defaultSubstituters
            );
            extra-trusted-public-keys = [nixCommunityKey];
            builders-use-substitutes = true;
          };

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
