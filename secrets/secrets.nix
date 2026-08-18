# agenix rules, derived from registry.nix. Pure builtins only: the agenix CLI evaluates this standalone, without nixpkgs lib.
let
  registry = import ./registry.nix;
in
  builtins.listToAttrs (
    map (name: {
      name = "${name}.age";
      value = {publicKeys = registry.${name}.recipients;};
    })
    (builtins.attrNames registry)
  )
