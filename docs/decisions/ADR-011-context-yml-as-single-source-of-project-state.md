# ADR-011: `.kiss/context.yml` is the single source of project state

**Date:** 2026-04-26
**Status:** Proposed
**Decider:** (decider: TBD — confirm)

## Context

KISS produces several state files under `<project>/.kiss/`:

- `context.yml` — paths, current feature, preferences, language,
  integrations.
- `init-options.json` — install options that affect the install
  itself.
- `integration.json` — pointer to the active integration(s).
- `integrations/<key>.manifest.json` — per-integration hashed file
  manifest (ADR-004).

Of these, `context.yml` is the *only* file that AI agents and
custom-agent skills read at the start of every session
(`CLAUDE.md`: *"Read `.kiss/context.yml`"*; agent prompts under
`subagents/architect/instructions.md` etc. start with the same
instruction). The other files are KISS's own bookkeeping.

`context.py:8-152` defines the embedded template for `context.yml`;
the rendered file matches the example shipped in the project's own
`.kiss/context.yml` (the one this repo carries for its own SDD
process).

## Decision

`<project>/.kiss/context.yml` is the **single source of project
state for AI agents**:

- KISS writes it on every `kiss init` (`context.py:8-152`).
- The schema is fixed at `schema_version: 1.0` and contains:
  - `paths.{docs, specs, plans, tasks, templates, scripts}`
  - `current.{feature, spec, plan, tasks, checklist, branch}`
  - `preferences.{output_format, task_numbering,
    confirm_before_write, auto_update_context}`
  - `language.{output, interaction}`
  - `integrations: [keys]`
- New state that AI agents need MUST be added to `context.yml`
  with a schema version bump, not stored in a separate file.
- KISS-internal bookkeeping (manifests, init options) MUST NOT
  leak into `context.yml`; those stay in their dedicated files
  so agents do not have to ignore noise.

## Consequences

- (+) AI agents have one file to read. No fan-out across multiple
  state files.
- (+) Schema-versioned, so future migrations have a clear
  contract.
- (+) The user can hand-edit `context.yml` to retarget paths or
  switch active feature; KISS respects the edits on next run
  (`context.py:155-172`, `175-187`).
- (−) Changes to `context.yml` schema require a version bump and
  a migration step; adding a field is non-trivial.
- (−) The current `1.0` schema does not version individual
  sub-sections, so future `paths` additions must remain
  backward-compatible until a `2.0`.

## Alternatives considered

- **Per-feature state files under `.kiss/features/<id>.yml`** —
  rejected; would force agents to glob and merge.
- **TOML or JSON instead of YAML** — rejected; YAML is the
  team's preferred config format and matches the existing
  workflow / preset / extension manifests.
- **Database** — rejected (overkill, breaks offline-everything).

## Source evidence

- `src/kiss_cli/context.py:8-152` (template)
- `src/kiss_cli/context.py:155-172` (`load_context_file`)
- `src/kiss_cli/context.py:175-187` (`save_context_file`)
- `CLAUDE.md` (top-level instruction to read `context.yml`)
- `AGENTS.md` (same instruction repeated)
