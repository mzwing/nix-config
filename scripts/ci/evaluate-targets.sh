#!/usr/bin/env bash
# Every host configuration this repository can cache, for mzwing/nix-actions' distributed-build workflow.
set -euo pipefail

# Same contents whichever system you read it from; this job runs on x86_64-linux.
# Assign before printing: inside `printf ... "$(nix eval)"` a failed eval still exits 0, so the step goes green with an empty output and the failure only surfaces later as a JSON parse error in plan-builds.
targets="$(nix eval --json '.#legacyPackages.x86_64-linux.ci.targets')"
printf 'targets=%s\n' "${targets}" >>"${GITHUB_OUTPUT}"
