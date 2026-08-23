# Evaluated by mzwing/nix-actions' gc-store and store-cache/reconcile, whose `drvs-file` input defaults to this path:
#   nix eval --impure --json --file ci/drvs.nix
# Full retention set; the scheduled derivations reach the actions separately.
# --impure for the unlocked git+file: ref.
(builtins.getFlake "git+file://${toString ../.}").legacyPackages."x86_64-linux".ci.drvs
