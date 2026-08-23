#!/usr/bin/env bash
# Evaluate the CI target list and the root devenv outputs for every supported system.
set -euo pipefail

# Same contents whichever system you read it from; this job runs on x86_64-linux.
CI_ATTR='.#legacyPackages.x86_64-linux.ci'

# Assign before printing: inside `printf ... "$(nix eval)"` a failed eval still exits 0, so the step goes green with an empty output and the failure only surfaces later as a JSON parse error in plan-builds.
targets="$(nix eval --json "${CI_ATTR}.targets")"
systems="$(nix eval --json "${CI_ATTR}.systems")"

printf 'targets=%s\n' "${targets}" >>"${GITHUB_OUTPUT}"

devenv_outputs='{}'
while IFS= read -r system; do
  # devenv-nixpkgs-patched sets allowSubstitutes = false, so pre-seed it — a foreign system cannot build it locally.
  patched_src="$(DEVENV_SYSTEM="${system}" nix eval --raw --impure --file ci/devenv-patched-src.nix)"
  if ! nix copy --from https://devenv.cachix.org "${patched_src}"; then
    printf '::warning::Could not pre-seed %s from devenv.cachix.org; foreign-system devenv evaluation may fail.\n' "${patched_src}"
  fi
  packages="$(devenv eval -s "${system}" packages | jq -c .packages)"
  devenv_outputs="$(jq -c --arg system "${system}" --argjson packages "${packages}" \
    '. + {($system): $packages}' <<<"${devenv_outputs}")"
done < <(jq -r '.[]' <<<"${systems}")
printf 'devenv_outputs=%s\n' "${devenv_outputs}" >>"${GITHUB_OUTPUT}"
