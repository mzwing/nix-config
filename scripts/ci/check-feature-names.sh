#!/usr/bin/env bash
# A feature's declared name must match its path — core/nix.nix -> "core/nix", nixos/server/default.nix -> "nixos/server".
# Typed by hand, so nothing else catches drift.
set -euo pipefail

status=0

while IFS= read -r file; do
  relative="${file#modules/features/}"
  expected="${relative%.nix}"
  expected="${expected%/default}"

  found=0
  while IFS= read -r declared; do
    found=1
    if [[ "${declared}" != "${expected}" ]]; then
      printf '::error file=%s::declared as "%s" but its path says "%s"\n' \
        "${file}" "${declared}" "${expected}"
      status=1
    fi
  done < <(sed -n 's/.*mzwing\.features\."\([^"]*\)".*/\1/p' "${file}")

  if ((found == 0)); then
    printf '::error file=%s::declares no feature\n' "${file}"
    status=1
  fi
done < <(git ls-files 'modules/features/*.nix')

if ((status == 0)); then
  printf 'All feature names match their paths.\n'
fi

exit "${status}"
