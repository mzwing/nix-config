#!/usr/bin/env bash
# Work out which realised outputs go to Cachix, and which derivations reconciliation should treat as this run's active set.
# Only final outputs are published: built host configuration paths plus the devenv shells of the systems that succeeded. Everything else built on the builders stays in the private store cache.
set -euo pipefail

jq -r '.[].drvPath' <<<"${TARGETS}" | sort --unique >/tmp/active-drvs.txt
jq -r '.[].outputPath' <<<"${TARGETS}" >/tmp/target-outputs.txt
grep '^/nix/store/' /tmp/built-outputs.txt 2>/dev/null |
  grep -Fxf /tmp/target-outputs.txt >/tmp/push-outputs.txt || true

if [[ -s /tmp/devenv-outputs.txt ]]; then
  cat /tmp/devenv-outputs.txt >>/tmp/push-outputs.txt
fi
sort --unique -o /tmp/push-outputs.txt /tmp/push-outputs.txt

printf 'Publishing %s outputs to Cachix.\n' "$(wc -l </tmp/push-outputs.txt)"
