# CI host configurations — every host with its local-only features
# stripped (see meta.ci.mode in modules/core/options.nix) — as
#
#   { darwin = { <name> = <darwinSystem>; ... };
#     nixos  = { <name> = <nixosSystem>;  ... }; }
#
# Evaluated here, outside the flake outputs, rather than exported as a
# flake output like the regular configurations in modules/core/flake.nix:
# `nix flake check` warns about non-standard flake outputs, and these
# configurations are only consumed by the ci/*.nix entry points anyway.
#
# Like the other ci/*.nix files the flake is fetched via git+file: (the
# committed git tree — well, the tracked files of the working tree,
# exactly like `nix eval .#...`), and the module tree is imported from
# the fetched flake source so this sees the same files the flake does.
let
  flake = builtins.getFlake "git+file://${toString ../.}";
  eval = flake.inputs.flake-parts.lib.evalFlakeModule {
    inputs = flake.inputs // {self = flake;};
  } (flake.inputs.import-tree (flake.outPath + "/modules"));
  inherit (eval.config.mzwing) hosts lib;
in {
  darwin = builtins.mapAttrs (_: host: lib.mkDarwinCIHost host) hosts.darwin;
  nixos = builtins.mapAttrs (_: host: lib.mkNixosCIHost host) hosts.nixos;
}
