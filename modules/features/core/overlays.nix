{
  mzwing.features."core/overlays" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    system = {inputs, ...}: {
      nixpkgs.overlays = [
        inputs.nur.overlays.default
        inputs.nix-vscode-extensions.overlays.default
      ];
    };
  };
}
