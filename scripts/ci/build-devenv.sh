#!/usr/bin/env bash
# Build the root devenv shell for every scheduled system.
# `devenv build` has no --keep-going, so try every system and report all failures at the end rather than stopping at the first.
set -euo pipefail

printf '### Built root devenv systems\n\n' >>"${GITHUB_STEP_SUMMARY}"

: >/tmp/devenv-outputs.txt
failed_systems=()
while IFS= read -r system; do
  # See scripts/ci/evaluate-targets.sh for why this pre-seed is needed.
  patched_src="$(DEVENV_SYSTEM="${system}" nix eval --raw --impure --file ci/devenv-patched-src.nix)"
  if ! nix copy --from https://devenv.cachix.org "${patched_src}"; then
    printf '::warning::Could not pre-seed %s from devenv.cachix.org; foreign-system devenv build may fail.\n' "${patched_src}"
  fi
  if timeout --signal=INT --kill-after=5m "${DEVENV_TIMEOUT_MINUTES}m" \
    devenv build shell -s "${system}" --max-jobs 0 --no-tui; then
    # shellcheck disable=SC2016  # backticks are markdown for the step summary
    printf -- '- `%s`\n' "${system}" >>"${GITHUB_STEP_SUMMARY}"
    jq -r --arg system "${system}" '.[$system][]' <<<"${DEVENV_OUTPUTS}" >>/tmp/devenv-outputs.txt
  else
    failed_systems+=("${system}")
  fi
done < <(jq -r '.[]' <<<"${DEVENV_SYSTEMS}")

if ((${#failed_systems[@]} > 0)); then
  printf '::error::devenv build failed for: %s\n' "${failed_systems[*]}"
  exit 1
fi
