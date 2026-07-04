# mzwing nix-config

Import-free, dendritic Nix configuration for macOS and NixOS.

## Shape

`flake.nix` only wires `flake-parts` and `import-tree`. Every real `.nix` file
under `modules/` is imported as a top-level module, so new behavior is added by
placing a feature, profile, or host declaration in the right directory.

```text
modules/
  core/       schema, helpers, flake outputs
  features/   feature records with optional darwin/nixos/home fragments
  profiles/   reusable feature lists
  hosts/      host declarations
```

## Outputs

- `darwinConfigurations.mzwing-MacBook-Pro`
- `nixosConfigurations.mzwing-do-sgp`
- `darwinModules`, `nixosModules`, `homeModules`
- `devShells`, `formatter`

## Commands

```bash
just show
just flake-check
just darwin-hosts
just darwin
just nixos-hosts
just nixos-build mzwing-do-sgp
just fmt
```

## Adding Config

Add a feature under `modules/features/<area>/<name>.nix` and register it as
`mzwing.features."<area>/<name>"`. A feature can provide any combination of:

- `darwin`
- `nixos`
- `home`

Then add the feature id to a profile in `modules/profiles/` or directly to a
host in `modules/hosts/`.
