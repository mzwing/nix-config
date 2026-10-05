let
  # timonwong.shellcheck 0.43 made contributes.configuration an array, which the jq in nixpkgs' postInstall cannot index. Drop once nix-community/nix-vscode-extensions#196 is fixed.
  vscodeShellcheckConfigArray = final: prev: {
    vscode-marketplace-release =
      final.lib.updateManyAttrsByPath [
        {
          path = [
            "timonwong"
            "shellcheck"
          ];
          update = extension:
            extension.overrideAttrs {
              postInstall = ''
                cd "$out/$installPrefix"
                jq '(.contributes.configuration[].properties."shellcheck.executablePath" | select(.)).default = "${final.shellcheck}/bin/shellcheck"' package.json | sponge package.json
              '';
            };
        }
      ]
      prev.vscode-marketplace-release;
  };
in {
  mzwing.features."core/overlays" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    system = {inputs, ...}: {
      nixpkgs.overlays = [
        inputs.nur.overlays.default
        inputs.nix-vscode-extensions.overlays.default
        vscodeShellcheckConfigArray
      ];
    };
  };
}
