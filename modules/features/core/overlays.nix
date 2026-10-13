let
  # nixpkgs hardcodes lldb's store path into debugpy on darwin, but test_lldb_command still expects a bare `lldb`. Drop once NixOS/nixpkgs#572564 reaches nixpkgs-unstable.
  debugpyLldbTest = _: prev: {
    pythonPackagesExtensions =
      prev.pythonPackagesExtensions
      ++ [
        (_: pyPrev: {
          debugpy = pyPrev.debugpy.overridePythonAttrs (old: {
            disabledTests = old.disabledTests ++ ["test_lldb_command"];
          });
        })
      ];
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
      ];
    };

    darwin.nixpkgs.overlays = [debugpyLldbTest];
  };
}
