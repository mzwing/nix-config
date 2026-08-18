# Schema for the feature/host registry. A feature is a named capability contributing up to three module fragments; a host picks features by name.
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

        requires = mkOption {
          type = types.listOf types.str;
          default = [];
          description = "Features pulled in transitively when this one is selected. Also how profiles work: a profile is a feature with no modules of its own.";
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
          description = ''Platforms ("darwin", "nixos") this feature may be selected on. Enforced: selecting it elsewhere is an evaluation error.'';
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
      description = ''What this host is for. Passed to every module as a specialArg, so one feature can serve both roles without being split into separate files — e.g. `lib.mkIf (type == "desktop")` around its GUI parts.'';
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
      description = "Host-local modules not worth making into features. By convention they sit next to the host with an underscore prefix, which import-tree skips.";
    };
  };

  darwinHostType = types.submodule (
    {name, ...}: {
      options =
        commonHostOptions name
        // {
          system = mkOption {
            type = types.enum [
              "aarch64-darwin"
              "x86_64-darwin"
            ];
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
      description = "The top-level option of my nix config.";
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
