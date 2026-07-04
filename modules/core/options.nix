{lib, ...}: let
  inherit (lib) mkOption types;

  featureType = types.submodule (
    {name, ...}: {
      options = {
        name = mkOption {
          type = types.str;
          default = name;
          description = "Path-like feature identifier.";
        };

        darwin = mkOption {
          type = types.nullOr types.deferredModule;
          default = null;
          description = "Optional nix-darwin module fragment.";
        };

        nixos = mkOption {
          type = types.nullOr types.deferredModule;
          default = null;
          description = "Optional NixOS module fragment.";
        };

        home = mkOption {
          type = types.nullOr types.deferredModule;
          default = null;
          description = "Optional Home Manager module fragment.";
        };

        meta.platforms = mkOption {
          type = types.listOf types.str;
          default = [];
          description = "Human-readable platform hints for this feature.";
        };
      };
    }
  );

  darwinHostType = types.submodule (
    {name, ...}: {
      options = {
        hostname = mkOption {
          type = types.str;
          default = name;
        };

        system = mkOption {
          type = types.enum [
            "aarch64-darwin"
            "x86_64-darwin"
          ];
          default = "aarch64-darwin";
        };

        username = mkOption {type = types.str;};
        useremail = mkOption {
          type = types.str;
          default = "";
        };

        profiles = mkOption {
          type = types.listOf types.str;
          default = [];
        };

        features = mkOption {
          type = types.listOf types.str;
          default = [];
        };
      };
    }
  );

  nixosHostType = types.submodule (
    {name, ...}: {
      options = {
        hostname = mkOption {
          type = types.str;
          default = name;
        };

        system = mkOption {
          type = types.enum [
            "x86_64-linux"
            "aarch64-linux"
          ];
          default = "x86_64-linux";
        };

        username = mkOption {
          type = types.str;
          default = "mzwing";
        };

        useremail = mkOption {
          type = types.str;
          default = "";
        };

        profiles = mkOption {
          type = types.listOf types.str;
          default = [];
        };

        features = mkOption {
          type = types.listOf types.str;
          default = [];
        };

        hardware = mkOption {
          type = types.nullOr types.path;
          default = null;
          description = "Optional host hardware module path.";
        };
      };
    }
  );
in {
  options.mzwing = {
    features = mkOption {
      type = types.attrsOf featureType;
      default = {};
      description = "The top-level option of my nix config.";
    };

    profiles = mkOption {
      type = types.attrsOf (types.listOf types.str);
      default = {};
      description = "Reusable lists of feature identifiers.";
    };

    hosts = {
      darwin = mkOption {
        type = types.attrsOf darwinHostType;
        default = {};
      };

      nixos = mkOption {
        type = types.attrsOf nixosHostType;
        default = {};
      };
    };

    lib = mkOption {
      type = types.attrsOf types.raw;
      default = {};
      description = "Helpers derived from the feature and host registry.";
    };
  };
}
