# Output path of devenv's patched nixpkgs, without realising it:
#   DEVENV_SYSTEM=x86_64-linux nix eval --raw --impure --file ci/devenv-patched-src.nix
# That tree is marked allowSubstitutes = false, so nix tries to build it locally and fails for foreign systems. The workflows `nix copy` this path from devenv.cachix.org first.
# Mirrors cachix/devenv-nixpkgs' default.nix.
let
  system = builtins.getEnv "DEVENV_SYSTEM";

  devenvLock = builtins.fromJSON (builtins.readFile ../devenv.lock);
  nixpkgsNode = devenvLock.nodes.root.inputs.nixpkgs;
  devenvNixpkgs = builtins.fetchTree devenvLock.nodes.${nixpkgsNode}.locked;

  srcLock = builtins.fromJSON (builtins.readFile (devenvNixpkgs + "/flake.lock"));
  nixpkgsSrc = builtins.fetchTree srcLock.nodes.nixpkgs-src.locked;

  pkgs = import "${nixpkgsSrc}" {inherit system;};
  patchDefs = pkgs.callPackage "${devenvNixpkgs}/patches" {};
in
  (pkgs.applyPatches {
    name = "devenv-nixpkgs-patched";
    src = nixpkgsSrc;
    patches = patchDefs.upstream ++ patchDefs.local;
  })
  .outPath
