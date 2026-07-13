# nix config

My nix config for macOS and NixOS.

The NixOS part is under construction.

Reference welcome, but my config is not intended to be used as a template for your own config. It is highly opinionated and tailored to my personal preferences and workflow.

## Structure

- `environments/` - contains examples of [devenv](https://devenv.sh) config for different languages and tools
- `modules/` - contains nix modules for system configuration, including nix-darwin and NixOS

## Usage

```shell
devenv shell # to quick start a shell with all required tools, default shell is bash
# If you want customized shell, use this:
devenv shell --shell {bash, zsh, fish, nu}

just # list all available shortcut commands
just darwin # to build and apply nix-darwin config
just typecheck # to type check the nix config
```

## Darwin CI cache

The trusted `master` workflow builds `ciConfigurations.darwin` on distributed
GitHub-hosted Apple Silicon runners and publishes newly built paths to the
public `mzwing` Cachix cache. Features marked with
`meta.ci.mode = "local-only"` remain in normal host configurations but are
removed from the CI configurations. In particular, the Android SDK, NDK,
emulator, and bundled CMake packages are never downloaded by Actions.

The workflow requires these GitHub Actions secrets:

- `CACHIX_AUTH_TOKEN` with write access to the `mzwing` cache
- `TS_OAUTH_CLIENT_ID` for a Tailscale OAuth client
- `TS_OAUTH_SECRET` for the same OAuth client

The OAuth client must be allowed to create `tag:nix-ci-builder` and
`tag:nix-ci-coordinator` nodes. Tailnet policy must allow the coordinator tag
to reach the builder tag and use Tailscale SSH as `root`. Pull requests only
run `.github/workflows/tests.yml`; the build workflow and its secrets are not
available to them.

## Credits

- [Misaka13514/flake](https://github.com/Misaka13514/flake)
- [AsterisMono/nixcn-conf-2605-flakesharing](https://github.com/AsterisMono/nixcn-conf-2605-flakesharing)
- [ryan4yin/nix-darwin-kickstarter](https://github.com/ryan4yin/nix-darwin-kickstarter)

Super thx [Misaka13514](https://github.com/Misaka13514) for patient guidance and great help with my config!!!!!

## License

MIT License.
