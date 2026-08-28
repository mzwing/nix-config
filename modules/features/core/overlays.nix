# Everything that rewrites nixpkgs. A package patch added here should say what would let it go: none of them are meant to outlive their upstream fix.
let
  overlaysModule = {inputs, ...}: {
    nixpkgs.overlays = [
      inputs.nur.overlays.default
      inputs.nix-vscode-extensions.overlays.default
    ];
  };
in {
  mzwing.features."core/overlays" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    darwin = overlaysModule;
    nixos = overlaysModule;
  };
}
