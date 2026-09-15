#!/usr/bin/env bash
# Which realised outputs go to Cachix, and which derivations are this run's active set.
# /tmp/built-outputs.txt comes from mzwing/nix-actions' nix/build-targets.
set -euo pipefail

jq -r '.[].drvPath' <<<"${TARGETS}" | sort --unique >/tmp/active-drvs.txt
jq -r '.[].outputPath' <<<"${TARGETS}" >/tmp/target-outputs.txt
grep '^/nix/store/' /tmp/built-outputs.txt 2>/dev/null |
  grep -Fxf /tmp/target-outputs.txt | sort --unique >/tmp/push-outputs.txt || true

printf 'Publishing %s outputs to Cachix.\n' "$(wc -l </tmp/push-outputs.txt)"
