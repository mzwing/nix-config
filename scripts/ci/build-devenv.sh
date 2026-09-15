#!/usr/bin/env bash
# Build the root devenv shell for every system this run's fleet can build for. devenv's own Cachix push daemon publishes whatever it realises, so nothing here collects or reconciles output paths.
set -euo pipefail

# Gitignored, so only CI ever pushes; a developer shell stays pull-only.
printf '{ cachix.push = "mzwing"; }\n' >devenv.local.nix

# Sits after the 200-minute target build inside the coordinator's 350.
timeout_minutes=60

# The coordinator realises nothing itself (--max-jobs 0), so a system with no builder cannot produce even devenv's small derivations. Builders are scheduled from the target list, so a system no host is built for never gets one.
fleet="$(jq -r '[.include[].system] | unique' <<<"${BUILDERS_JSON}")"
ci_systems="$(nix eval --json '.#legacyPackages.x86_64-linux.ci.systems')"
mapfile -t systems < <(jq -r --argjson fleet "${fleet}" '.[] | select(. as $s | $fleet | index($s))' <<<"${ci_systems}")
mapfile -t skipped < <(jq -r --argjson fleet "${fleet}" '.[] | select(. as $s | $fleet | index($s) | not)' <<<"${ci_systems}")

((${#skipped[@]} == 0)) ||
  printf '::warning::No builder for %s in this run; their devenv shells stay unbuilt.\n' "${skipped[*]}"

((${#systems[@]} > 0)) || exit 0

printf '### Built root devenv systems\n\n' >>"${GITHUB_STEP_SUMMARY}"

# `devenv build` has no --keep-going, so collect failures and report at the end.
failed_systems=()
for system in "${systems[@]}"; do
  if timeout --signal=INT --kill-after=5m "${timeout_minutes}m" \
    devenv build shell -s "${system}" --max-jobs 0 --no-tui; then
    # shellcheck disable=SC2016  # backticks are markdown for the step summary
    printf -- '- `%s`\n' "${system}" >>"${GITHUB_STEP_SUMMARY}"
  else
    failed_systems+=("${system}")
  fi
done

if ((${#failed_systems[@]} > 0)); then
  printf '::error::devenv build failed for: %s\n' "${failed_systems[*]}"
  exit 1
fi
