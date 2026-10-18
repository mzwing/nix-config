---
name: semver
description: Choose and apply SemVer version numbers under a policy that reserves majors for significant changes, and write dependency version requirements. Covers the public API, which bump a change gets, 0.y.z, pre-releases and build metadata, deprecations, immutable releases, tags, and where Cargo, npm, Go, and Python differ. Use when cutting a release, bumping or proposing a version, adding a changeset, judging whether a change is breaking, tagging, or editing a dependency's version requirement.
---

# SemVer

A version number tells whoever depends on the code how much an upgrade changes. Format and ordering follow [Semantic Versioning 2.0.0](https://semver.org/), but the bump policy below departs from it on purpose: the spec requires a major for every breaking change, while here a major is reserved for significant ones. Where an ecosystem adds to or departs from the spec, see [references/ecosystems.md](references/ecosystems.md).

## Start from what exists

- Read the project's release process before touching a version: release docs, existing tags, the changelog, and release tooling such as release-please, semantic-release, changesets, or cargo-release.
- When a tool derives the version from commits or changeset files, never edit the version by hand; give the tool its input, such as a commit type or a changeset. If its rules would cut a major for a change that isn't significant, raise it with the user.
- In a project with a `.changeset` directory, create each changeset by running `changeset add` through the project's package manager, never by writing a Markdown file into `.changeset` yourself. Pass each package's bump and the summary as flags, as in `pnpm changeset add --minor pkg-a --patch pkg-b -m 'Add the retry option'`; before `@changesets/cli` 3.0 the bumps can only be picked interactively, so give the user the command to run, with the bumps to pick and the summary to enter.
- A version changes when a release is cut, not as a side effect of an ordinary change, unless the project's process says otherwise.
- Bump through the project's own release command or script when it has one, so every copy of the version moves together; otherwise update every file that records this package's version.
- In a monorepo, follow its scheme: lockstep versions move together, independent ones move by each package's own changes.
- Follow the existing tag format (`v1.2.3`, `1.2.3`, `pkg@1.2.3`). The `v` belongs to the tag name; the version itself is `1.2.3`.

## The public API decides

SemVer constrains only the public API, so settle what that is first: everything consumers can observe and rely on, such as exported code, CLI flags, output and exit codes, config and file formats, wire protocols, environment variables, and documented behavior. Private code is outside it, however much it changes.

## Pick the bump

List the changes since the last release (`git log <last-tag>..HEAD`), classify each, and take the highest:

- MAJOR: only a significant breaking change or a significant feature update.
- MINOR: new features, improvements users will notice, deprecations, and breaking changes too small for a major.
- PATCH: bug fixes, dependency updates that leave your own API unchanged, and changes users won't notice.

A breaking change is significant when consumers have to rework how they use the project: a redesigned API, a removed core feature, or a config or data format that needs migration. Renaming an option, dropping an old runtime version, or tightening an edge case is not. A feature update is significant when it changes what the project does or how it is used, not when it adds another option or command. If a change isn't clearly significant, it doesn't get a major.

Reset everything right of the bumped number: `1.4.2` becomes `2.0.0` or `1.5.0`, never `1.5.2`.

Conventional Commits give a first guess: `fix` points to a patch, `feat` to a minor, and `!` or a `BREAKING CHANGE` footer to a breaking change, which is a major only when significant. Still read the diff, since a commit can be mislabeled.

When a minor ships a breaking change, call it out in the changelog or release notes. If the user asks for a smaller bump than the changes need, say so before applying it.

## 0.y.z

- `0.y.z` is initial development, where the spec lets anything change. The first release is `0.1.0`.
- Before `1.0.0`, breaking changes and new features bump `y` and everything else bumps `z`; Cargo and npm treat `y` as the compatibility boundary there, and every `0.0.z` release as breaking.
- `1.0.0` declares the public API stable. Software in production or with users depending on its API should probably be there already, but that call is the maintainer's: propose it, don't make it.

## Pre-releases and build metadata

- A pre-release follows a hyphen and sorts below its release: `1.0.0-alpha.1 < 1.0.0-beta < 1.0.0-rc.1 < 1.0.0`. Pre-release the version you are heading to: after `1.2.3`, a beta of the next minor is `1.3.0-beta.1`, never `1.2.3-beta.1`, which sorts below `1.2.3`.
- Put the counter after a dot. Numeric identifiers compare as numbers, so `rc.10` sorts after `rc.2`, while `rc10` compares as text and sorts before `rc2`.
- Pre-release identifiers use only `[0-9A-Za-z-]`, are never empty, and numeric ones have no leading zeros.
- Build metadata after a `+` (`1.0.0+20130313`) is ignored for precedence, so it never tells two releases apart.

## Released versions are immutable

- Never change what a released version contains: no moving or re-pushing a tag, no republishing under the same number. Every fix ships as a new version.
- Retire a bad release with the ecosystem's mechanism rather than deleting it.
- A release that breaks consumers by accident gets a new release that restores compatibility, and the broken version is documented.

## Deprecate before removing

Deprecate first, in a minor release with docs pointing at the replacement. Remove only in a later release; the removal is a breaking change, sized like any other.

## Dependency requirements

- Allow updates up to the dependency's next breaking boundary, written in the ecosystem's syntax.
- The lower bound promises that every version from there up works; raise it when the code starts using something newer.
- Libraries don't pin exact versions, which forces conflicts or duplicates on their consumers; applications get reproducible builds from their lockfile.
