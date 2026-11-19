{config, ...}: {
  mzwing.features."core/overlays" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    system = {inputs, ...}: {
      nixpkgs.overlays =
        [
          inputs.nur.overlays.default
          inputs.nix-vscode-extensions.overlays.default
          inputs.js-toolchain-overlay.overlays.default
          inputs.qiuchenly-cli.overlays.default
        ]
        ++ builtins.attrValues config.mzwing.patches;
    };
  };
}
