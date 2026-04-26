# Feature Specification: kiss-install

**Feature Slug**: `kiss-install`
**Created**: 2026-04-26
**Status**: Draft (reverse-engineered)
**Mode**: auto
**Input**: `cli/integration.py:181-259,345-470`,
`integrations/__init__.py:14-84`,
`integrations/base.py:771-817`,
`integrations/manifest.py:50-265`.

> Note: There is no top-level `kiss install` command. The brief's
> `kiss-install` feature corresponds to
> `kiss integration install <key>` and `kiss integration switch
> <target>` — i.e. post-init management of the installed AI
> provider. See **RDEBT-019** for the naming question.

## Problem Statement

A developer who initialised a project with one AI provider may
later want to add a different AI provider, or replace the current
one with a different choice, *without* re-running `kiss init` from
scratch and *without* losing the rest of the project state. They
need:

- a command that adds an integration to an existing project;
- a clear single-vs-multi policy so they understand when they
  must uninstall first vs. switch atomically;
- a rollback guarantee if the new install fails halfway through.

Source evidence: `src/kiss_cli/cli/integration.py:181-259`
(install), `:345-470` (switch),
`src/kiss_cli/integrations/__init__.py:14-84` (registry),
`src/kiss_cli/integrations/manifest.py:50-265` (per-install
manifest).

## User Scenarios & Testing

### User Story 1 — Install a single integration into an existing kiss project (Priority: P1)

As a developer who ran `kiss init` without picking an integration
(or with a different one), I want to run
`kiss integration install copilot` to add Copilot's prompts and
skills to my project, with a manifest tracking every file
written.

**Why this priority**: Headline post-init action; the user can't
use a new AI tool against the project until its skills are
installed.

**Independent test**: In an existing kiss project, run the
install; confirm `.github/skills/` exists, the manifest is
written, and the integration is listed by `kiss integration list`.

**Acceptance Scenarios**:

1. **Given** a kiss project with no integration installed,
   **When** the user runs `kiss integration install copilot`,
   **Then** the command writes the per-AI files, saves
   `.kiss/integrations/copilot.manifest.json`, sets
   `.kiss/integration.json` to `{"integration": "copilot", …}`,
   and prints "Integration 'GitHub Copilot' installed
   successfully" (`cli/integration.py:236-259`).
2. **Given** the user is not inside a kiss project (no `.kiss/`),
   **When** the command runs, **Then** it exits with code `1`
   and prints "Not a kiss project (no .kiss/ directory)"
   (`cli/integration.py:193-197`).
3. **Given** the user passes an unknown key, **When** the command
   runs, **Then** it exits with code `1` and prints the
   available integrations (`cli/integration.py:199-204`).

### User Story 2 — Install an additional integration alongside an existing one (Priority: P1)

As a developer who already has Claude installed, I want
`kiss integration install copilot` to add Copilot's prompts and
skills to my project alongside Claude — because multi-integration
support is a first-class feature both at init time and post-init.

**Acceptance Scenarios**:

1. **Given** Claude is already installed (per
   `.kiss/integration.json`), **When** the user runs
   `kiss integration install copilot`, **Then** the command
   writes the per-AI files for Copilot, saves
   `.kiss/integrations/copilot.manifest.json`, appends
   `copilot` to `.kiss/integration.json`'s `integrations`
   list, and
   prints "Integration 'GitHub Copilot' installed
   successfully" (`cli/integration.py`).
2. **Given** the same setup, **When** the user runs
   `kiss integration install claude` (the same one that's
   installed), **Then** the command exits with code `0` and
   prints "Integration 'claude' is already installed"
   (`cli/integration.py:209-212`).

> **Resolved (2026-04-26):** Multi-integration is supported
> both at `kiss init` and post-init via
> `kiss integration install`. Each integration owns its own
> disjoint directory tree and its own manifest. See former
> **RDEBT-009** (now resolved).

### User Story 3 — Switch integrations atomically (Priority: P1)

As a developer moving from Cursor to Windsurf, I want to run
`kiss integration switch windsurf` so that kiss removes the
Cursor install (preserving any modified files) and sets up the
Windsurf install in the same step — with rollback if the new
install fails.

**Acceptance Scenarios**:

1. **Given** Cursor is installed, **When** the user runs
   `kiss integration switch windsurf`, **Then** the command:
   (a) tears down Cursor, (b) sets up Windsurf, (c) writes the
   new manifest, (d) updates `.kiss/integration.json`, and
   (e) prints "Switched to integration 'Windsurf'"
   (`cli/integration.py:345-470`).
2. **Given** the same setup, **When** the new Windsurf setup
   raises an exception mid-flight, **Then** the command attempts
   to teardown the partial Windsurf install via
   `target_integration.teardown(..., force=True)`, removes
   `.kiss/integration.json`, and exits with code `1`
   (`cli/integration.py:458-467`).
3. **Given** the user passes `--force` to switch, **When** the
   target integration is partially installed already, **Then**
   the override forces overwrite of any modified target files.

### User Story 4 — Install with a script-flavour preference (Priority: P2)

As a developer on Windows who keeps Bash for tests, I want to
pass `--script ps` (or `--script sh`) to the install so that the
chosen flavour is recorded in `.kiss/init-options.json` and
honoured by downstream skills.

**Acceptance Scenarios**:

1. **Given** the user passes `--script ps`, **When** the install
   completes, **Then** the script-type preference is recorded
   (`cli/integration.py:184,219`).
2. **Given** no `--script` is passed, **When** the install runs,
   **Then** kiss defaults to the value in `.kiss/init-options.json`,
   falling back to the platform default (`sh` on POSIX, `ps` on
   Windows).

### User Story 5 — Install with integration-specific options (Priority: P2)

> **Note (2026-04-26):** the original Generic-integration user
> story has been removed because `generic` was removed from the
> source per ADR-018. The `--integration-options` flag remains
> in the CLI surface (`cli/integration.py:181-244`) but applies
> to the seven supported AIs only.

**Acceptance Scenarios**:

1. **Given** the user passes a valid options string for one
   of the seven supported integrations, **When** the install
   runs, **Then** the parsed options dict is passed into
   `integration.setup` (`cli/integration.py:232-242`).

### User Story 6 — List installed and available integrations (Priority: P2)

As a developer wondering what is installed, I want to run
`kiss integration list` to see all built-in integrations marked
with their status, and `kiss integration list --catalog` to see
the wider catalog.

**Acceptance Scenarios**:

1. **Given** Claude is installed, **When** the user runs
   `kiss integration list`, **Then** Claude appears with status
   "installed" and the rest with no status
   (`cli/integration.py:91-179`).
2. **Given** the user runs with `--catalog`, **When** the
   command runs, **Then** the catalog table shows every
   discoverable entry with version + source columns
   (`cli/integration.py:109-151`).

### Edge Cases

- **`.kiss/` directory missing** (i.e. user is not in a kiss
  project): every install / switch command exits with code `1`
  (`cli/integration.py:193-197`,
  `:373-377`).
- **Catalog read error** when `--catalog` is supplied:
  exits with code `1` and prints the error
  (`cli/integration.py:114-118`).
- **Mid-install exception**: rollback runs via
  `integration.teardown(..., force=True)` then exits with
  code `1` (`cli/integration.py:248-256`).
- **Network unavailable**: install MUST still complete; assets
  come from the bundled `core_pack/`
  (`tests/test_offline.py`).
- **Manifest mismatch on switch**: the existing integration's
  files may be locally modified — by default `teardown` skips
  modified files; `--force` removes them
  (`cli/integration.py:264-343`).
- **Permission denied on a target write**: surfaces as the
  underlying `OSError`; rollback path runs. Exact wording is
  undocumented (RDEBT-016).
- **Multiple integrations**: post-init, multiple integrations
  can coexist — each owns a disjoint directory tree and a
  separate manifest. `kiss integration install` adds to the
  set; `kiss integration switch` replaces one with another.
- **Catalog network access**: `kiss integration list --catalog`
  reads catalogs from disk in the bundled flow; community
  catalogs may require network — see **RDEBT-023**.

## Requirements

### Functional Requirements

- **FR-001**: The CLI MUST expose
  `kiss integration list [--catalog]`,
  `kiss integration install <key> [--script sh|ps]
  [--integration-options "<flags>"]`, and
  `kiss integration switch <target> [--script] [--force]
  [--integration-options]` (`cli/integration.py:91,181,345`).
- **FR-002**: All sub-commands MUST verify the current working
  directory is a kiss project (`.kiss/` exists); missing
  `.kiss/` MUST exit with code `1`
  (`cli/integration.py:193-197,272-276,373-377,489-493`).
- **FR-003**: `install` MUST resolve `<key>` against
  `INTEGRATION_REGISTRY` and reject unknown keys with code `1`
  (`cli/integration.py:199-204`).
- **FR-004**: `install` MUST allow installing an additional
  integration alongside any already-installed integrations;
  each integration owns a disjoint directory tree and a
  separate manifest. Installing `<key>` when `<key>` is
  already installed MUST short-circuit per FR-005.
- **FR-005**: `install` MUST short-circuit with exit code `0`
  when `<key>` is already the installed integration
  (`cli/integration.py:209-212`).
- **FR-006**: `install` MUST resolve the script type via
  `_resolve_script_type` (`cli/integration.py:219`,
  honouring `--script` → `.kiss/init-options.json` →
  platform-default order).
- **FR-007**: `install` MUST call `_install_shared_infra` to
  ensure `.kiss/` is present, and `ensure_executable_scripts`
  on POSIX (`cli/integration.py:223-225`).
- **FR-008**: `install` MUST create a fresh
  `IntegrationManifest`, call `integration.setup(...)`, save the
  manifest, write `.kiss/integration.json`, and update
  `.kiss/init-options.json`
  (`cli/integration.py:227-245`).
- **FR-009**: On `setup` failure, `install` MUST attempt
  rollback via `integration.teardown(..., force=True)`, remove
  `.kiss/integration.json`, and exit with code `1`
  (`cli/integration.py:247-256`).
- **FR-010**: `switch` MUST be a two-phase operation: teardown
  current → setup target, with a rollback path if the second
  phase fails (`cli/integration.py:345-470`).
- **FR-011**: `list` (without `--catalog`) MUST render a Rich
  table with columns `Key | Name | Status | CLI Required`,
  marking the currently-installed integration
  (`cli/integration.py:153-179`).
- **FR-012**: `list --catalog` MUST render a Rich table with
  columns `ID | Name | Version | Source | Status`
  (`cli/integration.py:123-151`).
- **FR-013**: All install operations MUST use the file-by-file
  SHA-256 manifest contract (`integrations/manifest.py:50-265`).
- **FR-014**: `install` MUST NOT perform network I/O; assets
  resolve via `_locate_core_pack`
  (`installer.py:301-315`).

### Non-Functional Requirements

- **NFR-001 (Offline)**: Install / switch MUST not perform
  network I/O during file writes (ADR-003); catalog operations
  may require network — see **RDEBT-023**.
- **NFR-002 (Cross-platform)**: Linux + Windows confirmed in CI;
  macOS asserted (RDEBT-005 / TDEBT-014).
- **NFR-003 (Shell parity)**: Both flavours MUST be installed
  per skill (ADR-006 / ADR-015).
- **NFR-004 (Coverage)**: ≥ 80 % on changed files (RDEBT-006 /
  TDEBT-015).
- **NFR-005 (Complexity / size)**: Functions ≤ 40 LOC,
  cyclomatic complexity ≤ 10, nesting ≤ 3 (Principle III /
  RDEBT-007).
- **NFR-006 (Lint)**: Zero Ruff warnings on changed files
  (ADR-016).
- **NFR-007 (Atomicity / rollback)**: A failed install MUST
  leave the project either (a) in its pre-install state or
  (b) clearly marked as failed via missing `.kiss/integration.json`,
  per FR-009.

### Key Entities

- **`INTEGRATION_REGISTRY`** — module-level dict at
  `src/kiss_cli/integrations/__init__.py:16`, populated by
  `_register_builtins()` at lines 40-81. Target state per
  ADR-018: exactly seven built-ins (Claude Code, Copilot,
  Cursor Agent, OpenCode, Windsurf, Gemini CLI, Codex).
  User-supplied registrations are not supported (ADR-009).
- **`IntegrationBase`** subtypes — `MarkdownIntegration`,
  `TomlIntegration`, `SkillsIntegration`. Each owns a target
  folder and an output format (ADR-005,
  `integrations/base.py:865+`).
- **`IntegrationManifest`** — per-install state; see
  `kiss-init/spec.md` Key Entities.
- **`.kiss/integration.json`** — pointer file recording all
  installed integrations as `{integrations: [keys], version}`
  (`installer.py:595-605`).

## Success Criteria

### Measurable Outcomes

- **SC-001**: `kiss integration install <key>` followed by
  `kiss integration list` shows `<key>` as `installed` 100 % of
  the time, across all seven supported built-in integrations
  (per ADR-018).
- **SC-002**: Switching from any built-in to any other built-in
  leaves no orphan files from the previous install — verified
  via the manifest's `uninstall` accounting.
- **SC-003**: A simulated mid-install failure (raise from
  `setup`) produces `.kiss/integration.json` absent and no
  partially-written manifest.
- **SC-004**: Install / switch perform zero network I/O —
  defended by the offline test suite.

## Assumptions

- The user has run `kiss init` previously, so `.kiss/` exists
  and contains `init-options.json` + `integration.json`.
- The user can install multiple integrations post-init via
  repeated `kiss integration install <key>` calls. Each
  integration owns a disjoint directory tree.
- The integration's external CLI (e.g. Claude Code, Copilot CLI)
  has either been installed by the user, or its absence is
  acceptable (the integration writes prompt files; it does not
  start the AI tool).

## Out of Scope

- Authoring or registering custom (non-built-in) integrations;
  the registry is static (ADR-009).
- Installing more than one integration with a single
  `integration install` call (each `install` adds one
  integration; `kiss init` supports multi-select).
- Re-running `setup` against an integration already at the
  current version (that's `kiss integration upgrade`).
- Discovery / health checks of the external AI CLIs themselves
  (covered by `kiss check` in `integration-system/spec.md`).

## Traceability

- **ADRs**: ADR-003 (offline), ADR-004 (manifests), ADR-005
  (three formats), ADR-006 (parity), ADR-009 (static registry),
  ADR-011 (context.yml).
- **Source modules**:
  `src/kiss_cli/cli/integration.py:91-470` (list, install,
  switch);
  `src/kiss_cli/integrations/__init__.py:14-84`;
  `src/kiss_cli/integrations/base.py:56-1374` (base classes,
  setup/teardown);
  `src/kiss_cli/integrations/manifest.py:50-265`.
- **Tests**: `tests/test_init_multi.py` (multi-AI flow exercises
  install paths indirectly).
- **Related specs**: `integration-system/spec.md` (cross-cutting
  contract), `kiss-uninstall/spec.md`, `kiss-init/spec.md`,
  `kiss-upgrade/spec.md`.
- **Related debts**: RDEBT-005, RDEBT-006, RDEBT-009 (resolved
  — multi-integration supported), RDEBT-019 (naming),
  RDEBT-023 (catalog network),
  RDEBT-024 (resolved — source narrowed to 7 AIs);
  cross-link TDEBT-028 (resolved).
