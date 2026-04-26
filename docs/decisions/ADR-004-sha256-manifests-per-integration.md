# ADR-004: SHA-256 manifests per integration with diff-aware uninstall

**Date:** 2026-04-26
**Status:** Proposed
**Decider:** (decider: TBD — confirm)

## Context

KISS writes potentially hundreds of files into a user's project
during `kiss init` (skills, agent prompts, commands, workflows).
On uninstall or upgrade, KISS must distinguish *its own* files
(safe to remove) from *files the user has edited since install*
(must be preserved or flagged). Naive deletion loses user work;
naive preservation accumulates stale files.

The codebase records every install in a per-integration manifest
at `<project>/.kiss/integrations/<key>.manifest.json`. The
manifest stores `{key, version, installed_at, files: {path: sha256}}`
(`integrations/manifest.py:50-265`). At uninstall, KISS rehashes
each tracked file and skips any whose hash diverges from the
manifest unless `--force` is passed (`cli/integration.py:319-343`).

## Decision

Every integration **MUST** maintain a SHA-256 manifest of every
file it writes:

- File: `<project>/.kiss/integrations/<integration_key>.manifest.json`.
- Schema: `{key: str, version: str, installed_at: ISO-8601 str,
  files: {relative_path: sha256_hex}}`.
- Behaviour:
  - `kiss integration uninstall` removes only files whose current
    on-disk SHA-256 matches the manifest. Modified files are
    counted in the "skipped" tally and reported to the user.
  - `kiss integration uninstall --force` removes regardless.
  - `kiss integration upgrade` is diff-aware: files unchanged
    from the previous install are overwritten silently; modified
    files are surfaced.
  - On install failure, `integration.teardown(..., force=True)`
    rolls the manifest back (`cli/integration.py:248-256`).

## Consequences

- (+) User edits survive upgrades (the *primary* user-trust
  invariant for a code-generator tool).
- (+) Uninstall is reversible in a useful sense — only KISS's
  own bytes are touched.
- (+) Manifests are human-readable JSON; users can inspect them.
- (−) Hashing N files on every install/uninstall costs CPU; not
  measurable on dev laptops at current scale.
- (−) Two integrations writing to the same path would collide
  silently; mitigated by `_validate_install_conflicts`
  (`extensions.py:747-765`) and the static integration registry
  (ADR-009).

## Alternatives considered

- **Timestamp-based diffing** — rejected; clock skew + file copy
  semantics make this unreliable across platforms.
- **Git-managed `.kiss/`** — rejected; would force every user
  project into git and expose KISS's bookkeeping in user diffs.
- **No diff awareness, manual conflict resolution** — rejected;
  silently destroys user work.

## Source evidence

- `src/kiss_cli/integrations/manifest.py:50-265`
- `src/kiss_cli/cli/integration.py:319-343` (uninstall flow)
- `src/kiss_cli/cli/integration.py:248-256` (rollback on error)
- `src/kiss_cli/installer.py:23` (`INTEGRATION_JSON`)
