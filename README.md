# nix config

My nix config for macOS and NixOS.

The NixOS part is under construction.

Reference welcome, but my config is not intended to be used as a template for your own config. It is highly opinionated and tailored to my personal preferences and workflow.

## Structure

```
data/           plain data, imported from anywhere: cache URLs and keys,
                China mirrors, SSH public keys. Lives outside modules/
                because import-tree treats every .nix under modules/ as a
                flake-parts module.
modules/
  flake/        the framework: the feature/host schema, how features are
                selected and assembled into systems, and the flake outputs
  features/     reusable capabilities, each contributing up to three module
                fragments (nix-darwin / NixOS / Home Manager)
    profiles/   features with no modules of their own, only `requires` —
                a named bundle, e.g. "everything my servers share"
    software/   one feature per application area
  hosts/        my machines; each picks features by name. A host is a single
                .nix file, or a directory with default.nix plus host-local
                modules prefixed with _ (import-tree skips any path
                containing "/_")
ci/             the one CI helper that is not expressible as a flake output
scripts/        bootstrap and CI shell/python helpers
secrets/        agenix secrets, and the registry naming them
environments/   examples of devenv config for different languages and tools
```

A feature declares which platforms it applies to, and may `requires` other
features; selecting one pulls in its dependencies transitively. Selecting a
feature that does not apply to the host's platform is an evaluation error
rather than a silent no-op.

## Usage

```shell
devenv shell # to quick start a shell with all required tools, default shell is bash
# If you want customized shell, use this:
devenv shell --shell {bash, zsh, fish, nu}

just # list all available shortcut commands
just darwin # to build and apply nix-darwin config
just darwin mzwing-MacBook-Pro debug # same, with --show-trace --verbose
just flake-check # evaluate every host and run the checks
just typecheck # to type check the nix config
```

## Bootstrap a new Mac

There is a chicken-and-egg problem to get past first. This config installs
sing-box from NUR, but on a fresh machine nix cannot reliably reach NUR — or
nixpkgs — without a proxy, and it cannot build the config that would provide
one. Two things exist to break the loop:

- `flake.nix`'s `nixConfig` lists the China mirrors ahead of everything else,
  so `--accept-flake-config` puts a fresh machine on them before any of this
  config has been applied. It has to be a literal there — Nix rejects
  `import` in `nixConfig` with "flake configuration setting ... is a thunk" —
  so it repeats `data/caches.nix` and
  `modules/features/network/china-mirrors.nix`, and the copies are kept in
  step by hand.
- `scripts/darwin_set_proxy.py` points the nix-daemon at a proxy you already
  have — a phone hotspot, say. It is standard-library-only and needs neither
  nix nor the devenv shell, because at that moment neither is available:

  ```shell
  sudo python3 scripts/darwin_set_proxy.py http://10.0.0.2:1080
  # ... build the config, which installs a real proxy ...
  sudo python3 scripts/darwin_set_proxy.py --unset
  ```

## CI cache

This repo will use GitHub Actions to build and cache the packages which not yet cached in the substituters.

What CI builds is a flake output — `just ci-targets` shows it.

Most design is originally from [Misaka13514/flake](https://github.com/Misaka13514/flake).

Currently I use Cachix, see <https://mzwing.cachix.org>.

## Credits

- [Misaka13514/flake](https://github.com/Misaka13514/flake)
- [AsterisMono/nixcn-conf-2605-flakesharing](https://github.com/AsterisMono/nixcn-conf-2605-flakesharing)
- [ryan4yin/nix-darwin-kickstarter](https://github.com/ryan4yin/nix-darwin-kickstarter)

Super thx [Misaka13514](https://github.com/Misaka13514) for patient guidance and great help with my config!!!!!

## License

MIT License.
