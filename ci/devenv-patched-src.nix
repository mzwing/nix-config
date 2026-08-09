# The output path of the `devenv-nixpkgs-patched` source tree for a given
# system, without realising it:
#
#   DEVENV_SYSTEM=x86_64-linux nix eval --raw --impure --file ci/devenv-patched-src.nix
#
# --impure is required for DEVENV_SYSTEM itself.
#
# devenv evaluates a patched nixpkgs (cachix/devenv-nixpkgs) whose
# applyPatches derivation is marked `allowSubstitutes = false`, so nix
# refuses to substitute it mid-evaluation and instead tries to build it
# locally — which fails for foreign systems in CI. The workflows pre-seed
# the store with
#
#   nix copy --from https://devenv.cachix.org "$path"
#
# where $path comes from this file, so that foreign-system `devenv eval`
# and `devenv build` find the patched source already valid.
#
# This mirrors cachix/devenv-nixpkgs' default.nix; only instantiation is
# required, so it evaluates quickly on any host.
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
