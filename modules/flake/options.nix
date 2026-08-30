{lib, ...}: let
  inherit (lib) mkOption types;

  packagesOption = description:
    mkOption {
      type = types.nullOr (types.functionTo (types.listOf types.package));
      default = null;
      inherit description;
    };

  moduleOption = description:
    mkOption {
      type = types.nullOr types.deferredModule;
      default = null;
      inherit description;
    };

  featureType = types.submodule (
    {name, ...}: {
      options = {
        name = mkOption {
          type = types.str;
          default = name;
          description = "Path-like feature identifier.";
        };

        requires = mkOption {
          type = types.listOf types.str;
          default = [];
          description = "Features pulled in with this one. A profile is a feature with nothing but these.";
        };

        system = moduleOption "Module fragment applied on both platforms.";
        darwin = moduleOption "nix-darwin module fragment.";
        nixos = moduleOption "NixOS module fragment.";
        home = moduleOption "Home Manager module fragment.";

        packages = {
          system = packagesOption "environment.systemPackages on both platforms.";
          darwin = packagesOption "environment.systemPackages on darwin.";
          nixos = packagesOption "environment.systemPackages on NixOS.";
          home = packagesOption "home.packages.";
        };

        meta.platforms = mkOption {
          type = types.listOf types.str;
          default = [];
          description = ''Platforms ("darwin", "nixos") this feature may be selected on; selecting it elsewhere is an evaluation error.'';
        };

        meta.ci.mode = mkOption {
          type = types.enum [
            "build"
            "local-only"
          ];
          default = "build";
          description = "Whether CI configurations should include this feature.";
        };
      };
    }
  );

  commonHostOptions = name: {
    hostname = mkOption {
      type = types.str;
      default = name;
    };

    type = mkOption {
      type = types.enum [
        "desktop"
        "server"
      ];
      description = ''What this host is for. A specialArg, so one feature can serve both roles — e.g. `lib.mkIf (type == "desktop")` around its GUI parts.'';
    };

    username = mkOption {type = types.str;};

    useremail = mkOption {
      type = types.str;
      default = "";
    };

    features = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Feature names to select; their `requires` come along.";
    };

    modules = mkOption {
      type = types.listOf types.deferredModule;
      default = [];
      description = "Host-local modules, by convention `_`-prefixed neighbours of the host file so import-tree skips them.";
    };
  };

  darwinHostType = types.submodule (
    {name, ...}: {
      options =
        commonHostOptions name
        // {
          system = mkOption {
            type = types.enum ["aarch64-darwin"];
            default = "aarch64-darwin";
          };
        };
    }
  );

  nixosHostType = types.submodule (
    {name, ...}: {
      options =
        commonHostOptions name
        // {
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
        };
    }
  );
in {
  options.mzwing = {
    features = mkOption {
      type = types.attrsOf featureType;
      default = {};
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
