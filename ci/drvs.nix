# Evaluated by mzwing/nix-actions' gc-store and store-cache/reconcile, whose `drvs-file` input defaults to this path:
#   nix eval --impure --json --file ci/drvs.nix
# Full retention set across inactive configurations; the actions receive the exact scheduled derivations separately.
# --impure for the unlocked git+file: ref.
(builtins.getFlake "git+file://${toString ../.}").legacyPackages."x86_64-linux".ci.drvs
