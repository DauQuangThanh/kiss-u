# Feature Specification: kiss-uninstall

**Feature Slug**: `kiss-uninstall`
**Created**: 2026-04-26
**Status**: Draft (reverse-engineered)
**Mode**: auto
**Input**: `cli/integration.py:261-343`,
`integrations/manifest.py:50-265`,
`integrations/base.py:819-835`.

> Note: There is no top-level `kiss uninstall` command. The
> brief's `kiss-uninstall` feature corresponds to
> `kiss integration uninstall [<key>] [--force]`. See
> **RDEBT-019**.

## Problem Statement

A developer who installed an AI-provider integration into a kiss
project may later want to remove it cleanly — taking only the
files kiss originally wrote, never touching anything the user has
modified, and leaving the rest of the project intact. They need:

- a one-command removal that uses the manifest as the
  authoritative file list (no guessing);
- a default-safe behaviour that skips files modified since
  install, plus an explicit `--force` opt-in to wipe them too;
- a clear post-condition on `.kiss/integration.json` and
  `.kiss/integrations/<key>.manifest.json`.

Source evidence: `src/kiss_cli/cli/integration.py:261-343`,
`src/kiss_cli/integrations/manifest.py:50-265` (the `uninstall`
helper that performs the hash-checked removal).

## User Scenarios & Testing

### User Story 1 — Uninstall a specific integration safely (Priority: P1)

As a developer who installed Claude into a kiss project but no
longer needs it, I want to run `kiss integration uninstall claude`
(or just `kiss integration uninstall` when only one is installed)
and have kiss remove every file it originally wrote — but skip any
file I have edited so I do not lose work.

**Why this priority**: Headline removal action; safety here
prevents user data loss.

**Independent test**: Install Claude, modify one of its files,
run uninstall, and confirm (a) the modified file is preserved,
(b) all unmodified install-time files are gone, (c) the manifest
file is removed, (d) `.kiss/integration.json` is updated
(Claude removed from the `integrations` list).

**Acceptance Scenarios**:

1. **Given** Claude is installed and no kiss-managed files have
   been modified, **When** the user runs
   `kiss integration uninstall`, **Then** every file listed in
   the manifest is deleted, the manifest is removed, and
   `.kiss/integration.json` is cleared
   (`cli/integration.py:261-343`).
2. **Given** the user has edited one skill file, **When** the
   user runs `kiss integration uninstall` (no `--force`),
   **Then** the modified file is preserved, the rest are
   deleted, and the command reports the count of removed and
   preserved files (`cli/integration.py:336-343`).
3. **Given** the user re-runs `kiss integration uninstall`,
   **When** no integration is installed, **Then** the command
   exits with code `0` and prints "No integration is currently
   installed" (`cli/integration.py:281-285`).

### User Story 2 — Force-uninstall to wipe modified files (Priority: P2)

As a developer who knows their edits were experimental and
disposable, I want to pass `--force` so that even modified files
are removed.

**Acceptance Scenarios**:

1. **Given** modified kiss-managed files exist, **When** the
   user runs `kiss integration uninstall --force`, **Then**
   modified files are also removed
   (`cli/integration.py:264,329-335`).

### User Story 3 — Uninstall an explicitly-named integration (Priority: P3)

As a developer who recorded the install but is unsure which
integration is currently active, I want to pass the key
explicitly: `kiss integration uninstall claude` — and have kiss
verify the key matches the installed integration.

**Acceptance Scenarios**:

1. **Given** Claude is installed, **When** the user runs
   `kiss integration uninstall claude`, **Then** the command
   removes Claude (`cli/integration.py:281-289`).
2. **Given** Claude is installed but the user passes
   `copilot`, **When** the command runs, **Then** it exits with
   code `1` and prints "Integration 'copilot' is not the
   currently installed integration ('claude')."
   (`cli/integration.py:287-289`).

### Edge Cases

- **`.kiss/` directory missing** (not in a kiss project):
  exits with code `1` (`cli/integration.py:272-276`).
- **Manifest file missing for the integration**: the manifest
  loader will raise; the command reports the error and exits
  with code `1` (per the manifest contract,
  `integrations/manifest.py:50-265`). **(AI suggestion —
  confirm exact wording.)**
- **`.kiss/integration.json` records a different integration**:
  the named key is rejected per FR-005.
- **Files listed in the manifest that no longer exist on disk**:
  treated as "already removed" and counted as such in the
  manifest's `uninstall` accounting; not an error.
- **Permission denied on a target file**: surfaces as the
  underlying `OSError`. Behaviour is undocumented (RDEBT-016).
- **Network unavailable**: uninstall MUST still complete; it is
  pure filesystem work.
- **Partial uninstall (process killed mid-run)**: the manifest
  is the authoritative file list; re-running uninstall will
  remove whatever remains. **(AI suggestion — confirm)**.

## Requirements

### Functional Requirements

- **FR-001**: The CLI MUST expose
  `kiss integration uninstall [<key>] [--all] [--force]`
  (`cli/integration.py:261-264`). When `--all` is supplied,
  the CLI MUST uninstall every installed integration in
  sequence.
- **FR-002**: The CLI MUST verify `.kiss/` exists; missing
  `.kiss/` MUST exit with code `1`
  (`cli/integration.py:272-276`).
- **FR-003**: When `<key>` is omitted AND exactly one integration
  is installed, the CLI MUST default to that integration. When
  `<key>` is omitted AND multiple integrations are installed,
  the CLI MUST exit with code `1` and print the list of
  installed integrations, asking the user to specify which one
  to uninstall.
- **FR-004**: When no integration is installed AND no key is
  supplied, the CLI MUST exit with code `0` and print
  "No integration is currently installed"
  (`cli/integration.py:281-285`).
- **FR-005**: When `<key>` is supplied AND is not among the
  currently installed integrations, the CLI MUST exit with
  code `1` and print the list of installed integrations
  (`cli/integration.py:287-289`).
- **FR-006**: The CLI MUST load the per-integration manifest
  from `.kiss/integrations/<key>.manifest.json` and call its
  `uninstall(project_root, force=force)` method
  (`integrations/manifest.py:50-265`).
- **FR-007**: Without `--force`, the CLI MUST preserve any file
  whose current SHA-256 differs from the manifest record
  (modified files), reporting the count.
- **FR-008**: With `--force`, the CLI MUST remove every file
  listed in the manifest regardless of modification state
  (`cli/integration.py:264,329-335`).
- **FR-009**: The CLI MUST remove the per-integration manifest
  file after a successful uninstall.
- **FR-010**: The CLI MUST remove the key from
  `.kiss/integration.json`'s `integrations` list. If the
  list becomes empty, the file MUST contain
  `{"integrations": [], "version": "<kiss_version>"}`.
- **FR-011**: The CLI MUST report the count of files removed
  and the count of files skipped (preserved due to
  modification) (`cli/integration.py:336-343`).
- **FR-012**: The CLI MUST NOT touch files outside the manifest
  — directories not entirely empty after manifest-listed file
  removal MUST be preserved.
- **FR-013**: The CLI MUST NOT perform network I/O.

### Non-Functional Requirements

- **NFR-001 (Offline)**: Uninstall is pure filesystem work; no
  network calls (ADR-003).
- **NFR-002 (Cross-platform)**: Linux, Windows; macOS
  asserted (RDEBT-005 / TDEBT-014).
- **NFR-003 (Shell parity)**: N/A directly; the manifest-driven
  removal does not differentiate by shell — but parity in the
  install side ensures both flavours land in the manifest and
  thus get cleaned up identically.
- **NFR-004 (Coverage)**: ≥ 80 % on changed files (RDEBT-006).
- **NFR-005 (Complexity / size)**: ≤ 40 LOC, complexity ≤ 10
  (Principle III / RDEBT-007).
- **NFR-006 (Lint)**: Zero Ruff warnings on changed files
  (ADR-016).
- **NFR-007 (Safety)**: The default (non-`--force`) path MUST
  preserve user-modified files; this is the central invariant
  of ADR-004.

### Key Entities

- **`IntegrationManifest`** — the per-integration manifest
  driving the uninstall (`integrations/manifest.py:50-265`).
  Methods used: `load`, `check_modified`, `uninstall`.
- **`.kiss/integration.json`** — pointer file; the uninstalled
  key is removed from the `integrations` list on success.

## Success Criteria

### Measurable Outcomes

- **SC-001**: After `kiss integration uninstall` (without
  `--force`), zero files modified by the user since install
  are deleted (verified by the manifest's hash check).
- **SC-002**: After uninstall, every file present in the
  manifest at install time is either (a) absent from disk
  (clean removal) or (b) reported as "preserved (modified)".
- **SC-003**: After uninstall, `.kiss/integration.json` shows
  no installed integration, and `kiss integration list` reports
  the same.
- **SC-004**: Uninstall performs zero network I/O — defended by
  the offline test suite.

## Assumptions

- A `.kiss/integrations/<key>.manifest.json` exists for the
  installed integration (i.e. the install was performed by a
  recent kiss version that uses manifests).
- The integration's external CLI (e.g. Claude Code) is left
  untouched — kiss only removes files it wrote.
- The user does not need an interactive per-file
  confirmation (today only the binary `--force` flag exists;
  see RDEBT-010 for the analogous gap on upgrade).

## Out of Scope

- Removing the kiss CLI itself (handled by `uv tool uninstall
  kiss` — out of `kiss`'s own surface).
- Removing user-authored content under `docs/specs/`,
  `docs/plans/`, `docs/tasks/`. Those are never touched.
- Removing presets, extensions, or workflows alongside the
  integration — those have their own `remove` commands (see
  `preset-management/spec.md`, `extension-management/spec.md`,
  `workflow-engine/spec.md`).
- Migrating manifest schemas across kiss versions.

## Traceability

- **ADRs**: ADR-003 (offline), ADR-004 (manifests),
  ADR-005 (three formats), ADR-009 (registry).
- **Source modules**:
  `src/kiss_cli/cli/integration.py:261-343`;
  `src/kiss_cli/integrations/manifest.py:50-265`;
  `src/kiss_cli/integrations/base.py:819-835` (`teardown`).
- **Tests**: `tests/test_init_multi.py` exercises install +
  uninstall paths.
- **Related specs**: `kiss-install/spec.md`,
  `integration-system/spec.md`, `kiss-init/spec.md`,
  `kiss-upgrade/spec.md`.
- **Related debts**: RDEBT-005, RDEBT-006, RDEBT-016,
  RDEBT-019, RDEBT-024 (spec narrows to 7 AIs; code ships 13);
  cross-link TDEBT-028.
