---
name: write-docs
description: Write, edit, and review Markdown docs in any project, including READMEs, guides, references, changelogs, and agent instructions (AGENTS.md, CLAUDE.md, SKILL.md). Covers what each page is for, where each fact lives, values that go stale, pointers, and leftovers from the conversation that produced the page. Use when creating or changing docs, or when a page is about to record a version, a status, or a fact that already lives elsewhere.
---

# Write docs

Docs are read by people who never saw how they were made, and by agents as context for their next change. Every line has to hold for that reader, now and after the next release.

## Start from what exists

- Existing docs: keep their structure, tone, and format, and change only what the change needs. These rules govern new decisions; they are not a license to rewrite what is there.
- New pages: add one only when it has a job no existing page does.

## One page, one job

- README: scope and length follow the always-on rules; anything beyond them stays out, or gets its own page if the project keeps docs.
- Guide: the steps for one task, steps first, background and troubleshooting after.
- Reference: what exists, with its values and defaults.
- Changelog: what changed, dated.
- Agent instructions: commands, conventions, and boundaries; no project history.
- Why it was built this way goes in your reply, the commit or PR, or a decision record if the project keeps them. A guide or reference keeps only the one-line reason a step needs to make sense.
- A page that starts covering two unrelated tasks gets split, leaving one line and a link behind.

## One home per fact

- A fact that can change, such as an option list, a default, or a precedence order, lives in one place; everything else links to it.
- When the code owns the fact, point at the code instead of copying it.
- Restating a section and then linking to it leaves two copies. Keep the link, drop the restatement.

## Nothing that goes stale

Long-lived pages carry what stays true: purpose, usage, invariants, procedures. No current version, count, commit hash, deployment state, or "currently supports"; name where the answer is read instead, such as the lockfile, the manifest, or a command. A minimum version or supported range is fine when it is a real requirement. Changelogs keep the values they recorded.

## Pointers land

A pointer names a file plus a symbol, key, or heading. "See the source", a repository root, or a bare directory leaves the reader searching for what the sentence promised.

## Final state only

A page states what is, not how it got there; history lives in the changelog and git.

- No "as requested", "I added", "now supports", or "unlike before".
- No dropped options, and no negative scope ("without X") that nobody expected.
- No next steps or notes on how the page was produced.

## Claims

- Describe only behavior confirmed in the code, a spec, or an observed run; flag what you could not verify instead of filling the gap.
- "Faster", "recommended", and "better" need a measurement or source beside them, or the adjective goes.

## Verify

- Every local link and anchor resolves; a renamed heading breaks the links aimed at it.
- After a behavior change, grep the docs for the old wording and fix every copy.

## Reviewing

Report each finding as its location (`file:line`), what misleads the reader, and one fix. "Nothing to change" is a valid result.

Adapted from seiso (MIT, scarletkc) and the ux-writing and product-writing skills (Apache-2.0, scarletkc).
