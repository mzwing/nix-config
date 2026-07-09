darwin_host := "mzwing-MacBook-Pro"

default:
  @just --list

[group('darwin')]
darwin-hosts:
  @nix --accept-flake-config --quiet eval --no-warn-dirty --raw .#darwinConfigurations \
    --apply 'configs: (builtins.concatStringsSep "\n" (builtins.attrNames configs)) + "\n"'

[group('darwin')]
darwin host=darwin_host:
  nix build .#darwinConfigurations.{{host}}.system \
    --extra-experimental-features 'nix-command flakes'
  sudo -E ./result/sw/bin/darwin-rebuild switch --flake .#{{host}}

[group('darwin')]
darwin-debug host=darwin_host:
  nix build .#darwinConfigurations.{{host}}.system --show-trace --verbose \
    --extra-experimental-features 'nix-command flakes'
  sudo -E ./result/sw/bin/darwin-rebuild switch --flake .#{{host}} --show-trace --verbose

[group('nixos')]
nixos-hosts:
  @nix --accept-flake-config --quiet eval --no-warn-dirty --raw .#nixosConfigurations \
    --apply 'configs: (builtins.concatStringsSep "\n" (builtins.attrNames configs)) + "\n"'

[group('nixos')]
nixos-build host:
  nix build .#nixosConfigurations.{{host}}.config.system.build.toplevel --show-trace

[group('nix')]
flake-check:
  nix flake check --no-build --show-trace

[group('nix')]
typecheck:
  typenix --noEmit

[group('nix')]
show:
  nix flake show --no-write-lock-file

[group('nix')]
up:
  nix flake update

[group('nix')]
upp input:
  nix flake update {{input}}

[group('nix')]
history:
  nix profile history --profile /nix/var/nix/profiles/system

[group('nix')]
repl:
  nix repl -f flake:nixpkgs

[group('nix')]
clean:
  sudo nix profile wipe-history --profile /nix/var/nix/profiles/system --older-than 3d

[group('nix')]
gc:
  sudo nix-collect-garbage --delete-older-than 3d
  nix-collect-garbage --delete-older-than 3d

[group('nix')]
fmt:
  nix fmt

[group('nix')]
gcroot:
  ls -al /nix/var/nix/gcroots/auto/
