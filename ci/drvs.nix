# Evaluated by mzwing/nix-actions' gc-store, whose `drvs-file` input defaults to this path:
#   nix eval --impure --json --file ci/drvs.nix
(builtins.getFlake "git+file://${toString ../.}").legacyPackages."x86_64-linux".ci.drvs
