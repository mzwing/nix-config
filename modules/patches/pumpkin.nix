{
  # rustc 1.99 overflows its default stack compiling pumpkin-data. Drop once nixpkgs' pumpkin builds again.
  mzwing.patches.pumpkin = _: prev: {
    pumpkin = prev.pumpkin.overrideAttrs (old: {
      env = old.env // {RUST_MIN_STACK = "33554432";};
    });
  };
}
