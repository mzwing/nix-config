# Ecosystems

Where each ecosystem adds to or departs from SemVer 2.0.0. The project's own manifest and docs win over this page.

## Cargo

- The [Cargo SemVer compatibility guide](https://doc.rust-lang.org/cargo/reference/semver.html) classifies Rust changes as major (breaking), minor, or possibly-breaking; use it to decide whether a change is breaking instead of guessing, then size the bump by the skill's policy. Possibly-breaking entries, such as adding a defaulted trait item, need a judgment call.
- A plain requirement such as `"1.2.3"` is a caret requirement: `^1.2.3` is `>=1.2.3, <2.0.0`, `^0.2.3` is `>=0.2.3, <0.3.0`, and `^0.0.3` is `>=0.0.3, <0.0.4`.
- Adding a Cargo feature is compatible. Removing one is breaking, and so is removing an entry from a feature's list when that takes functionality away.
- Record the minimum Rust version in `package.rust-version` so dependency resolution can pick older releases for older toolchains.
- Retire a release with `cargo yank`.

## npm

- `^1.2.3` allows minor and patch updates, `^0.2.3` only patch updates, and `^0.0.3` none. `~1.2.3` allows patch updates only.
- A pre-release satisfies a range only when a comparator with the same `major.minor.patch` is itself a pre-release: `>1.2.3-alpha.3` matches `1.2.3-alpha.7` but not `3.4.5-alpha.9`.
- `npm version <major|minor|patch|premajor|preminor|prepatch|prerelease>` writes the version to `package.json` and the lockfile, and also commits and tags unless given `--no-git-tag-version`. `--preid rc` sets the pre-release label.
- Retire a release with `npm deprecate`.

## Go

- Versions are tags of the form `vMAJOR.MINOR.PATCH`; the `v` is required. A module in a subdirectory prefixes its tags with that path, as in `sub/v1.2.3`.
- From v2 on, the module path ends in the major version (`module example.com/mod/v2`), and every import of the module changes with it. v0 and v1 take no suffix.
- A `require` line is a minimum; minimal version selection picks the highest minimum in the build, so there are no ranges to write.
- Retire a release with a `retract` directive in `go.mod`; builds that already depend on it keep working.

## Python

- Python follows [PEP 440](https://packaging.python.org/en/latest/specifications/version-specifiers/), not SemVer: `major.minor.patch` carries over, but pre-releases and everything after the release number use PEP 440's own syntax.
- Pre-releases are `1.0.0a1`, `1.0.0b1`, and `1.0.0rc1`, development and post releases `1.0.0.dev1` and `1.0.0.post1`; they sort `.devN < aN < bN < rcN < release < .postN`. Tools normalize `1.0.0-rc.1` to `1.0.0rc1`, so write the normal form.
- `~=1.4.5` means `>=1.4.5, ==1.4.*`, and `~=2.2` means `>=2.2, ==2.*`.
- Local versions (`1.0.0+local`) are only for private builds; PyPI rejects them.
- Retire a release by yanking it on PyPI.
