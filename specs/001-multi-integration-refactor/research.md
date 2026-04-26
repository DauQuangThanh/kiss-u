# Research: multi-integration-refactor

**Date**: 2026-04-26

## Decision 1: `integration.json` migration strategy

**Decision**: Read-time migration shim (no file rewrite on read).

**Rationale**: The old format (`{"integration": "claude"}`) exists
on every installed kiss project. Rather than requiring a migration
command, `_read_integration_json` transparently converts the old
format to the new one in memory. The file is rewritten in the new
format on the next write operation (install, uninstall, upgrade).
This is zero-friction for existing users.

**Alternatives considered**:

- *Explicit `kiss migrate` command*: Rejected — adds user burden
  for a one-field schema change; violates Principle I (simplest
  path).
- *Dual-write (old + new fields)*: Rejected — the user chose to
  drop the singular field (clarification session Q4, answer B).

## Decision 2: `--all` flag vs interactive picker for multi-integration commands

**Decision**: `--all` flag for uninstall and upgrade; no
interactive picker.

**Rationale**: The CLI already has precedent for explicit flags
over interactive prompts in post-init commands. An interactive
picker would require `inquirer` or similar, adding a dependency
for a rare use case (most users have 1-2 integrations). The
`--all` flag is discoverable via `--help` and consistent with
Unix conventions.

**Alternatives considered**:

- *Interactive multi-select (like `kiss init`)*: Rejected — the
  init picker uses `inquirer` which is already a dependency for
  init, but post-init commands should be scriptable without
  TTY interaction.
- *Always operate on all*: Rejected — dangerous for uninstall;
  users should opt in to bulk operations.

## Decision 3: `dispatch_command` timeout — Popen vs threading

**Decision**: Replace `subprocess.run` with `subprocess.Popen` +
`process.wait(timeout)` + signal-based kill.

**Rationale**: `Popen` gives direct access to the process handle
for `terminate()` / `kill()`. The existing non-streaming path
already uses `subprocess.run(timeout=...)` which raises
`TimeoutExpired` — the streaming path should use the same
underlying mechanism but with explicit process lifecycle control.

**Alternatives considered**:

- *Threading with `subprocess.run`*: Rejected — adds threading
  complexity for no benefit; `Popen.wait(timeout)` is the
  standard approach.
- *`asyncio` with `create_subprocess_exec`*: Rejected — the CLI
  is synchronous; introducing async for one function violates
  Principle I.

## Decision 4: `context.yml` merge algorithm

**Decision**: Recursive dict merge where existing values win; new
keys are added with template defaults.

**Rationale**: A simple recursive merge covers the upgrade case:
the user's customizations (language, paths, preferences) are
preserved, while new schema keys introduced in a newer kiss
version are added with their template defaults. The
`schema_version` field is always updated to the new version.
The `integrations` list is union-merged (no duplicates).

**Alternatives considered**:

- *Full overwrite with backup*: Rejected — user explicitly
  requested preservation (clarification C-02).
- *JSON Patch / three-way merge*: Rejected — overkill for a
  flat-ish YAML file with ~20 keys; Principle I.
- *Prompt user per conflict*: Rejected — there are no real
  conflicts; existing values always win, new keys always add.

## Decision 5: Exit code for timeout (`124` vs `1`)

**Decision**: Exit code `124`, matching GNU `timeout` convention.

**Rationale**: Using `124` makes timeout distinguishable from
generic failure (`1`) and keyboard interrupt (`130`). GNU
`timeout` uses `124` for the same purpose, so it's a well-known
convention in Unix tooling. On Windows, the same exit code is
used for consistency.

**Alternatives considered**:

- *Exit code `1` (generic failure)*: Rejected — callers
  (workflow engine) need to distinguish timeout from other
  failures to decide retry vs abort.
- *Exit code `142` (128 + SIGALRM)*: Rejected — no SIGALRM is
  actually sent; `124` is the convention for "timed out".
