#!/usr/bin/env bash
# Which realised outputs go to Cachix, and which derivations count as this run's active set.
# Only final outputs are published: host configurations plus the devenv shells that succeeded. Everything else stays in the private cache.
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
