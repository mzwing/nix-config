darwin_host := "mzwing-MacBook-Pro"
repo_dir := justfile_directory()

# "." is git+file: and sees only tracked files; "path:<dir>" would copy the whole tree and choke on .codegraph/daemon.sock.
flake_ref := "."

# agenix only looks for ~/.ssh/id_rsa and ~/.ssh/id_ed25519 on its own, and this is neither: it decrypts secrets and logs into nothing.
age_identity := "~/.ssh/agenix"

default:
  @just --list

[group('darwin')]
darwin-hosts:
  @nix --accept-flake-config --quiet eval --raw {{flake_ref}}#darwinConfigurations \
    --apply 'configs: (builtins.concatStringsSep "\n" (builtins.attrNames configs)) + "\n"'

# Pass `debug` to add --show-trace --verbose.
[group('darwin')]
darwin host=darwin_host debug='':
  #!/usr/bin/env bash
  set -euo pipefail

  case "{{debug}}" in
    '') flags='' ;;
    debug) flags='--show-trace --verbose' ;;
    *) printf 'darwin only accepts "debug" as its second argument\n' >&2; exit 2 ;;
  esac

  nix build ".#darwinConfigurations.{{host}}.system" \
    --extra-experimental-features 'nix-command flakes' ${flags}
  sudo -E ./result/sw/bin/darwin-rebuild switch --flake ".#{{host}}" ${flags}

[group('nixos')]
nixos-hosts:
  @nix --accept-flake-config --quiet eval --raw {{flake_ref}}#nixosConfigurations \
    --apply 'configs: (builtins.concatStringsSep "\n" (builtins.attrNames configs)) + "\n"'

# Push this flake to a remote host and rebuild there. Pass `debug` for --verbose --debug.
[group('nixos')]
nixos host target action='switch' debug='':
  #!/usr/bin/env bash
  set -euo pipefail

  case "{{action}}" in
    boot|switch|test) ;;
    *) printf 'nixos only accepts boot, switch, or test as its action\n' >&2; exit 2 ;;
  esac

  case "{{debug}}" in
    '') flags='' ;;
    debug) flags='--verbose --debug' ;;
    *) printf 'nixos only accepts "debug" as its fourth argument\n' >&2; exit 2 ;;
  esac

  flake_path="$(nix flake metadata --no-write-lock-file --json {{flake_ref}} | jq -r .path)"
  nix copy --to "ssh-ng://{{target}}" "$flake_path"
  ssh -o ServerAliveInterval=15 -o ServerAliveCountMax=4 "{{target}}" nixos-rebuild \
    --flake "path:$flake_path#{{host}}" \
    --accept-flake-config \
    --show-trace \
    ${flags} \
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

# Names as registry.nix spells them, without the .age suffix that `secret` adds back.
[group('secrets')]
secrets:
  @nix --accept-flake-config --quiet eval --raw --file {{repo_dir}}/secrets/registry.nix \
    --apply 'r: (builtins.concatStringsSep "\n" (builtins.attrNames r)) + "\n"'

# Edit one secret in $EDITOR; saving re-encrypts it to whoever registry.nix says may read it.
[group('secrets')]
secret name:
  cd {{repo_dir}}/secrets && agenix -e {{name}}.age -i {{age_identity}}

# Re-encrypt every secret. Run after changing recipients or adding a host.
[group('secrets')]
rekey:
  cd {{repo_dir}}/secrets && agenix --rekey -i {{age_identity}}

[group('nix')]
flake-check:
  nix flake check --show-trace {{flake_ref}} --all-systems

# What CI would build and cache.
[group('nix')]
ci-targets:
  @nix eval --json .#legacyPackages.x86_64-linux.ci.targets | jq

[group('nix')]
typecheck:
  typenix --noEmit

[group('nix')]
show:
  nix flake show --no-write-lock-file {{flake_ref}}

# Re-resolve the pinned skill sources; a rebuild never does.
[group('nix')]
skills-update:
  nix run {{flake_ref}}#skills-sources-lock

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
