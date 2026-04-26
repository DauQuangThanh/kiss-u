# Implementation Plan: multi-integration-refactor

**Branch**: `001-multi-integration-refactor` | **Date**: 2026-04-26 | **Spec**: [spec.md](spec.md)
**Input**: Updated specs from `docs/specs/integration-system/`, `kiss-install/`, `kiss-uninstall/`, `kiss-upgrade/`, `kiss-init/`

## Summary

Refactor the kiss CLI to support multiple simultaneously-installed
integrations post-init, enforce `dispatch_command` timeout with
process cleanup, and preserve user customizations in `context.yml`
during upgrades. The core change is migrating
`.kiss/integration.json` from a single-key model
(`{"integration": "claude"}`) to a list model
(`{"integrations": ["claude", "copilot"]}`), then updating every
consumer of that file.

## Technical Context

**Language/Version**: Python 3.11+ (existing codebase)
**Primary Dependencies**: Typer (CLI), Rich (output), PyYAML (context.yml), hatchling (build)
**Storage**: Filesystem (JSON manifests, YAML context)
**Testing**: pytest (existing suite in `tests/`)
**Target Platform**: Linux, Windows, macOS (cross-platform)
**Project Type**: CLI tool
**Performance Goals**: All commands complete within seconds (qualitative — RDEBT-002)
**Constraints**: Offline-only after install (ADR-003), ≤ 40 LOC per function (Principle III), ≥ 80% coverage on changed files
**Scale/Scope**: 7 supported integrations, ~1374 LOC in base.py, ~582 LOC in integration.py

## Standards Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Gate | Status | Notes |
|------|--------|-------|
| Test-First (Principle II) | PASS | Tests written before implementation per TDD cycle |
| Small Units (Principle III) | WATCH | `integration.py` functions are already near limits; refactoring must not grow them |
| Pure/Deterministic (Principle IV) | PASS | JSON/YAML I/O is at the edges; business logic is pure |
| Coverage ≥ 80% | WATCH | Changed files must maintain ≥ 80% — verify with `pytest --cov` |
| Lint zero-warnings | PASS | Ruff enforced via CI |
| Parity | N/A | No Bash/PowerShell changes in this refactoring |

## Project Structure

### Documentation (this feature)

```text
specs/001-multi-integration-refactor/
├── spec.md              # Feature spec (cross-references upstream specs)
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
└── contracts/
    └── integration-json-schema.md  # New integration.json contract
```

### Source Code (files to modify)

```text
src/kiss_cli/
├── cli/
│   ├── integration.py   # install, uninstall, switch, upgrade commands
│   └── check.py         # kiss check reporting
├── installer.py         # _write/_read_integration_json, _install_shared_infra
├── integrations/
│   └── base.py          # dispatch_command timeout handling
└── context.py           # create_context_file, merge logic (new)

tests/
├── test_multi_integration.py  # New: multi-integration lifecycle tests
├── test_dispatch_timeout.py   # New: timeout/kill behavior tests
├── test_context_merge.py      # New: context.yml merge-on-upgrade tests
├── test_check_output.py       # New: kiss check output improvements tests
└── (existing test files updated as needed)
```

**Structure Decision**: This is a refactoring of existing code — no
new modules or packages are introduced. The three new test files
keep each concern isolated per Principle III.

## Work Packages

### WP-1: `integration.json` schema migration (foundation)

**Why first**: Every other WP depends on this. The JSON file is
the central coordination point.

**Source files**:

- `src/kiss_cli/installer.py` lines 581-612

**Changes**:

1. `_write_integration_json(project_root, integration_key)` →
   `_write_integration_json(project_root, integrations: list[str])`
   Writes `{"integrations": [...], "version": "..."}`.
2. `_read_integration_json(project_root)` → returns
   `{"integrations": [...], "version": "..."}`. Migration shim:
   if the file has the old `"integration"` (singular) key, convert
   it to `{"integrations": [key]}` on read (one-time compat).
3. `_add_integration_to_json(project_root, key)` — new helper:
   reads, appends key if not present, writes.
4. `_remove_integration_from_json(project_root, key)` — new
   helper: reads, removes key, writes.
5. Delete `_remove_integration_json()` (no longer needed — the
   file persists with an empty list).

**Tests** (write first):

- Read old-format `{"integration": "claude"}` → returns
  `{"integrations": ["claude"]}`.
- Read new-format → returns as-is.
- Add key to empty list → list has one entry.
- Add duplicate key → no change.
- Remove key → list shrinks.
- Remove last key → list is empty, file persists.

### WP-2: `kiss integration install` — allow multi-integration

**Depends on**: WP-1

**Source files**:

- `src/kiss_cli/cli/integration.py` lines 181-260

**Changes**:

1. Remove lines 214-217 (the single-integration refusal guard).
2. Replace `_write_integration_json(project_root, key)` call
   with `_add_integration_to_json(project_root, key)`.
3. Keep the short-circuit for "already installed" (FR-005) —
   check if `key` is already in the `integrations` list.
4. Update `init-options.json` writing to append to `integrations`
   list instead of overwriting.

**Tests** (write first):

- Install `claude` into empty project → success, list =
  `["claude"]`.
- Install `copilot` alongside `claude` → success, list =
  `["claude", "copilot"]`.
- Install `claude` when already installed → exit 0, no-op.

### WP-3: `kiss integration uninstall` — multi-integration + `--all`

**Depends on**: WP-1

**Source files**:

- `src/kiss_cli/cli/integration.py` lines 261-343

**Changes**:

1. Add `--all` flag to the Typer command.
2. When `key` is omitted and exactly one integration installed →
   default to that one (existing behavior).
3. When `key` is omitted and multiple installed → exit 1, list
   installed, ask user to specify or use `--all`.
4. When `--all` → uninstall each in sequence.
5. Replace `_remove_integration_json()` with
   `_remove_integration_from_json(project_root, key)` per
   uninstalled integration.
6. Update `init-options.json` to remove the key from the list.

**Tests** (write first):

- Uninstall named key from multi-integration project → removes
  only that key's files + manifest; list updated.
- Uninstall with `--all` → removes all integrations.
- Omit key with multiple installed → exit 1 with helpful message.
- Omit key with single installed → defaults to it.

### WP-4: `kiss integration upgrade` — multi-integration + `--all`

**Depends on**: WP-1

**Source files**:

- `src/kiss_cli/cli/integration.py` lines 472-582

**Changes**:

1. Add `--all` flag to the Typer command.
2. When `key` is omitted and exactly one installed → default.
3. When `key` is omitted and multiple installed → exit 1, list
   installed, ask to specify or use `--all`.
4. When `--all` → upgrade each in sequence, stop at first failure.
5. Validate `key` is in the `integrations` list (via WP-1
   helpers).

**Tests** (write first):

- Upgrade named key → upgrades only that integration.
- Upgrade with `--all` → upgrades each in sequence.
- `--all` stops at first failure → already-upgraded ones are fine,
  remaining ones not attempted.
- Omit key with multiple installed → exit 1.

### WP-5: `dispatch_command` timeout enforcement

**Depends on**: None (independent)

**Source files**:

- `src/kiss_cli/integrations/base.py` lines 147-225

**Changes**:

1. In the streaming case (lines 192-212), replace
   `subprocess.run` with `subprocess.Popen` to get a process
   handle, then `process.wait(timeout=timeout)`.
2. On `TimeoutExpired`: send `SIGTERM`, wait 5s, then `SIGKILL`
   if still running. Return exit code `124`.
3. Print `"Command '<name>' timed out after <timeout>s"` to
   stderr.
4. On Windows: use `process.terminate()` then `process.kill()`
   (no SIGTERM/SIGKILL distinction).

**Tests** (write first):

- Mock subprocess that sleeps beyond timeout → process killed,
  exit code 124.
- Mock subprocess that exits within timeout → normal exit code.
- Mock subprocess that responds to SIGTERM within grace → clean
  shutdown.
- Windows path: terminate then kill.

### WP-6: `context.yml` merge-on-upgrade

**Depends on**: None (independent)

**Source files**:

- `src/kiss_cli/context.py` lines 155-187
- `src/kiss_cli/installer.py` lines 393-410
- `src/kiss_cli/cli/init.py` lines 148-183 (re-init path)

**Changes**:

1. Add `merge_context_file(project_path, new_integrations)` to
   `context.py`: loads existing context.yml, loads template
   defaults, deep-merges (existing values win, new keys added),
   writes back.
2. Update `_install_shared_infra` to call `merge_context_file`
   when `.kiss/context.yml` already exists, and
   `create_context_file` when it doesn't.
3. Update `kiss init --here --force` path in `cli/init.py` to
   call `merge_context_file` instead of `create_context_file`
   when `context.yml` exists.
4. Update `schema_version` if changed.
5. Append new integrations to the `integrations:` list without
   removing existing ones.

**Tests** (write first):

- Existing `context.yml` with `language.output: Vietnamese` +
  upgrade → Vietnamese preserved.
- Existing `context.yml` missing a new key (e.g. new
  `preferences.foo`) → key added with default.
- No existing `context.yml` → created from template.
- `integrations` list merged (no duplicates).

### WP-7: `kiss check` output improvements

**Depends on**: WP-1

**Source files**:

- `src/kiss_cli/cli/check.py` lines 1-639

**Changes**:

1. Refactor each sub-check to collect findings into a list of
   `CheckFinding(file, expected, actual, fix_suggestion)` instead
   of printing inline.
2. After all findings collected, render a Rich table grouped by
   sub-check: columns `File | Issue | Suggested Fix`.
3. Update `check_skills` and `check_integrations` to read from
   `integration.json`'s `integrations` list (via WP-1 helpers).
4. Ensure all sub-checks run to completion even when failures
   are found.

**Tests** (write first):

- Missing skill file → finding with fix suggestion.
- Multiple findings → all shown in one report.
- All checks pass → clean summary.

### WP-8: `kiss integration switch` adaptation

**Depends on**: WP-1, WP-2, WP-3

**Source files**:

- `src/kiss_cli/cli/integration.py` lines 345-470

**Changes**:

1. `switch` replaces one specific integration with another. New
   syntax: `kiss integration switch <from> <to>` (two positional
   args). When only one integration is installed, `<from>` can be
   omitted: `kiss integration switch <to>`.
2. When `<from>` is omitted and multiple are installed → exit 1
   with usage hint.
3. Update rollback path to use new helpers.

**Tests** (write first):

- Switch from `claude` to `copilot` in multi-integration project
  → `claude` removed, `copilot` added, others untouched.
- Switch with rollback on failure → source restored.

## Dependency Graph

```text
WP-1 (integration.json schema)
 ├── WP-2 (install)
 ├── WP-3 (uninstall)
 ├── WP-4 (upgrade)
 ├── WP-7 (check)
 └── WP-8 (switch) ── depends on WP-2, WP-3

WP-5 (dispatch timeout)  ── independent
WP-6 (context.yml merge) ── independent
```

**Recommended execution order**: WP-1 → WP-2 → WP-3 → WP-4 →
WP-8 → WP-7, with WP-5 and WP-6 in parallel at any time.

## Complexity Tracking

| Item | LOC Estimate | Risk |
|------|-------------|------|
| WP-1: JSON schema helpers | ~60 LOC (4 functions x ~15) | Low — pure JSON manipulation |
| WP-2: Install refactor | ~30 LOC delta (removal + replacement) | Low — removing code |
| WP-3: Uninstall refactor | ~50 LOC delta (add `--all`, multi-logic) | Medium — new control flow |
| WP-4: Upgrade refactor | ~50 LOC delta (add `--all`, multi-logic) | Medium — mirrors WP-3 |
| WP-5: Timeout enforcement | ~40 LOC delta (Popen + kill logic) | Medium — cross-platform signals |
| WP-6: Context merge | ~50 LOC (new function + caller update) | Low — YAML dict merge |
| WP-7: Check output | ~80 LOC delta (findings model + Rich table) | Low — output-only change |
| WP-8: Switch adaptation | ~30 LOC delta (adapt to new helpers) | Low — leverages WP-2/WP-3 |

**Total estimated delta**: ~390 LOC across 6 source files + ~400
LOC new tests across 3 test files.

No function should exceed 40 LOC (Principle III). WP-3, WP-4, and
WP-5 are the watch items — extract helpers early if approaching
the limit.

## Risk Register

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Old `integration.json` on existing installs | High | High | WP-1 migration shim reads old format transparently |
| `switch` semantics ambiguous with multi-integration | Medium | Medium | Require explicit `--from`/`<target>` pair |
| `dispatch_command` kill differs POSIX vs Windows | Medium | Low | Use `terminate()`/`kill()` abstraction |
| Check command performance with many integrations | Low | Low | 7 integrations max — O(n) is fine |
| context.yml merge loses unexpected custom keys | Medium | Low | Deep merge preserves all existing keys by default |
