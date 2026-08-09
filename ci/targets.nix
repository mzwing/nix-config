# Host configurations that CI builds and caches, as a flat list of
# {name, system, installable, outputPath} entries. Evaluated by the
# "Evaluate CI targets" step of .github/workflows/build.yml:
#
#   nix eval --impure --json --file ci/targets.nix
#
# The flake is fetched via git+file: (i.e. from the committed git tree,
# exactly like `nix eval .#...`) rather than path:, because the path:
# fetcher hashes the whole working directory including .git, which
# differs between checkouts and would make every evaluation produce
# different outputPaths. --impure is required for the unlocked ref; CI
# checkouts are clean, so evaluation stays deterministic per commit.
let
  flake = builtins.getFlake "git+file://${toString ../.}";
  inherit (flake.inputs.nixpkgs) lib;
  inherit (flake) ciConfigurations;

  systemOf = cfg: cfg.pkgs.stdenv.hostPlatform.system;
in
  lib.mapAttrsToList (name: cfg: {
    name = "darwin.${name}";
    system = systemOf cfg;
    installable = ".#ciConfigurations.darwin.${name}.system";
    outputPath = cfg.system.outPath;
  })
  ciConfigurations.darwin
  ++ lib.mapAttrsToList (name: cfg: {
    name = "nixos.${name}";
    system = systemOf cfg;
    installable = ".#ciConfigurations.nixos.${name}.config.system.build.toplevel";
    outputPath = cfg.config.system.build.toplevel.outPath;
  })
  ciConfigurations.nixos
