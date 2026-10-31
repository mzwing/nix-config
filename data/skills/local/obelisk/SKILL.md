---
name: obelisk
description: Search past Claude Code, pi, omp, and dsh sessions through the Obelisk CLI, which indexes the coding agents' transcripts on this machine into one SQLite database. Covers writing and running query scripts, choosing helpers, keeping results small, and reading them as evidence. Use when the user refers to earlier work you have no context for, including work done in another agent, asks how something was fixed or decided before, or when details a compaction dropped from the current session are needed.
---

# Obelisk

`obelisk` keeps the coding agents' transcripts in `~/.obelisk/obelisk.sqlite` and runs JavaScript query scripts against them. Every run refreshes the index first, so the current session is included.

## Run a query

1. Write the script to a fresh path under `/tmp`, such as `/tmp/obq-<random>.mjs`. The path as typed identifies your invocation, so never reuse one.
2. Run `obelisk --query <path>`. The script runs inside an async function, and whatever it returns is printed as JSON.
3. Answer from that JSON, citing session ids and dates.

If the refresh fails, for example on a read-only `~/.obelisk`, report that and stop: reading the transcripts or the database some other way is no substitute.

Memories stay with your own memory system; this skill never runs `obelisk --attune`.

## Helpers

- `overview({ limit: 6 })` maps projects and recent sessions. Start with it unless the user named an exact session, message, or file.
- `sessions()` finds sessions by project, time range, branch, or `source` (dsh's is `deepseek`).
- `search(text)` finds messages by topic.
- `messages()` reads one message, a window around it, or a page of a session. Expand hits with it instead of loading whole sessions.
- `fileHistory(absolutePath)` lists every tool call that touched a file, reads included, oldest first.
- `sql(query, ...params)` covers the joins and counts the helpers can't. Check [references/schema.md](references/schema.md) first.

Options and return shapes are in [references/api-reference.md](references/api-reference.md); look an option up there instead of guessing it.

## Keep results small

- Narrow before searching: project, file, session, or time range first. To ask whether Y came up while doing X, find the sessions for X and search for Y only inside them.
- Group, dedupe, and count inside the script. Return ids, timestamps, and snippets of about 200 characters, around 10k characters in all.
- `search()` is FTS5, where a hyphen splits a term; use `sql()` with `LIKE` when literal punctuation matters.
- An empty result for an exact scope is the answer. Don't widen the scope unless the user asks.

## Read results as evidence

- A session marked `is_invoking: true` is the current one, not history.
- A message's `content_type` decides what it can support: `text` is what the user or agent said, `thinking` is only a trace, and `tool_use` and `tool_result` point to the structured tool rows.
- Helpers skip `is_meta` rows, which are transcript plumbing; add `COALESCE(m.is_meta,0)=0` to raw SQL as well unless the plumbing is the question.
- pi and omp keep turns that a compaction or a branch left behind as inactive rows. Pass `includeInactive: true` when you need them, and say they were superseded.
