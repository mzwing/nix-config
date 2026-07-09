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

## Credits

- [Misaka13514/flake](https://github.com/Misaka13514/flake)
- [AsterisMono/nixcn-conf-2605-flakesharing](https://github.com/AsterisMono/nixcn-conf-2605-flakesharing)
- [ryan4yin/nix-darwin-kickstarter](https://github.com/ryan4yin/nix-darwin-kickstarter)

Super thx [Misaka13514](https://github.com/Misaka13514) for patient guidance and great help with my config!!!!!

## License

MIT License.
