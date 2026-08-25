# Everything that rewrites nixpkgs. Each patch says what would let it go, because none of them should outlive their upstream fix.
let
  # tmux 3.7c refuses to configure on macOS without an explicit jemalloc choice and nixpkgs passes neither, which breaks anything building it — skim runs its tests under tmux. Enabled rather than disabled because that is what the refusal is asking for: macOS calloc(3) does not reliably zero. Drop once nixpkgs picks one.
  tmuxJemalloc = final: prev: {
    tmux = prev.tmux.overrideAttrs (old: {
      buildInputs = old.buildInputs ++ [final.jemalloc];
      configureFlags = old.configureFlags ++ ["--enable-jemalloc"];
    });
  };
in {
  mzwing.features."core/overlays" = {
    meta.platforms = [
      "darwin"
      "nixos"
    ];

    darwin = {inputs, ...}: {
      nixpkgs.overlays = [
        inputs.nur.overlays.default
        tmuxJemalloc
      ];
    };

    # tmux builds fine here, and patching it would only cost a cache hit.
    nixos = {inputs, ...}: {
      nixpkgs.overlays = [
        inputs.nur.overlays.default
      ];
    };
  };
}
