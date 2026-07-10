darwin_host := "mzwing-MacBook-Pro"
flake_ref := "path:" + justfile_directory()
repo_dir := justfile_directory()

default:
  @just --list

[group('darwin')]
darwin-hosts:
  @nix --accept-flake-config --quiet eval --raw {{flake_ref}}#darwinConfigurations \
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
  @nix --accept-flake-config --quiet eval --raw {{flake_ref}}#nixosConfigurations \
    --apply 'configs: (builtins.concatStringsSep "\n" (builtins.attrNames configs)) + "\n"'

[group('nixos')]
nixos host target action='switch':
  #!/usr/bin/env bash
  set -euo pipefail

  case "{{action}}" in
    boot|switch|test) ;;
    *) printf 'nixos only accepts boot, switch, or test as its action\n' >&2; exit 2 ;;
  esac

  flake_path="$(nix flake metadata --no-write-lock-file --json {{flake_ref}} | jq -r .path)"
  nix copy --to "ssh-ng://{{target}}" "$flake_path"
  ssh -o ServerAliveInterval=15 -o ServerAliveCountMax=4 "{{target}}" nixos-rebuild \
    --flake "path:$flake_path#{{host}}" \
    --no-reexec \
    --no-write-lock-file \
    --accept-flake-config \
    --show-trace \
    "{{action}}"

[group('nixos')]
nixos-debug host target action='switch':
  #!/usr/bin/env bash
  set -euo pipefail

  case "{{action}}" in
    boot|switch|test) ;;
    *) printf 'nixos-debug only accepts boot, switch, or test as its action\n' >&2; exit 2 ;;
  esac

  flake_path="$(nix flake metadata --no-write-lock-file --json {{flake_ref}} | jq -r .path)"
  nix copy --to "ssh-ng://{{target}}" "$flake_path"
  ssh -o ServerAliveInterval=15 -o ServerAliveCountMax=4 "{{target}}" nixos-rebuild \
    --flake "path:$flake_path#{{host}}" \
    --no-reexec \
    --no-write-lock-file \
    --accept-flake-config \
    --show-trace \
    --verbose \
    --debug \
    "{{action}}"

[group('nixos')]
nixos-anywhere-preflight target:
  #!/usr/bin/env bash
  set -euo pipefail

  ssh "{{target}}" 'sh -s' <<'REMOTE'
  set -eu

  printf '### system ###\n'
  printf 'arch: %s\n' "$(uname -m)"
  printf '\n### disks ###\n'
  lsblk -o NAME,PATH,SIZE,TYPE,MOUNTPOINTS
  printf '\n### network links ###\n'
  ip -br link
  printf '\n### network addresses ###\n'
  ip -br addr
  printf '\n### ipv4 routes ###\n'
  ip route
  printf '\n### ipv6 routes ###\n'
  ip -6 route
  REMOTE

[group('nixos')]
nixos-anywhere host target no_reboot='':
  if [ -n '{{no_reboot}}' ] && [ '{{no_reboot}}' != '--no-reboot' ]; then echo 'nixos-anywhere only accepts --no-reboot as its optional argument' >&2; exit 2; fi
  nix run {{flake_ref}}#nixos-anywhere -- \
    --flake {{flake_ref}}#{{host}} \
    --target-host {{target}} \
    {{no_reboot}} \
    --build-on remote \
    --generate-hardware-config nixos-generate-config {{repo_dir}}/modules/hosts/nixos/{{host}}/_hardware.nix

[group('nix')]
flake-check:
  nix flake check --no-build --show-trace {{flake_ref}} --all-systems

[group('nix')]
typecheck:
  typenix --noEmit

[group('nix')]
show:
  nix flake show --no-write-lock-file {{flake_ref}}

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
