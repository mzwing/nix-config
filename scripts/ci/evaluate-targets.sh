#!/usr/bin/env bash
# Evaluate the CI target list and the root devenv outputs for every supported system.
set -euo pipefail

printf 'targets=%s\n' "$(nix eval --impure --json --file ci/targets.nix)" >>"${GITHUB_OUTPUT}"

devenv_outputs='{}'
for system in x86_64-linux aarch64-linux aarch64-darwin; do
  # devenv-nixpkgs-patched sets allowSubstitutes = false, so nix will not substitute it mid-evaluation and would try to build it locally, which cannot work for a foreign system. Pre-seed it instead.
  patched_src="$(DEVENV_SYSTEM="${system}" nix eval --raw --impure --file ci/devenv-patched-src.nix)"
  if ! nix copy --from https://devenv.cachix.org "${patched_src}"; then
    printf '::warning::Could not pre-seed %s from devenv.cachix.org; foreign-system devenv evaluation may fail.\n' "${patched_src}"
  fi
  packages="$(devenv eval -s "${system}" packages | jq -c .packages)"
  devenv_outputs="$(jq -c --arg system "${system}" --argjson packages "${packages}" \
    '. + {($system): $packages}' <<<"${devenv_outputs}")"
done
printf 'devenv_outputs=%s\n' "${devenv_outputs}" >>"${GITHUB_OUTPUT}"
