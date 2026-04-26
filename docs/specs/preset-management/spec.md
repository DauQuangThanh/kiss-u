# Feature Specification: preset-management

**Feature Slug**: `preset-management`
**Created**: 2026-04-26
**Status**: Draft (reverse-engineered)
**Mode**: auto
**Input**: `cli/preset.py:79-669`,
`presets.py:1-2098`,
`presets/` (3 bundled presets: `lean/`, `scaffold/`,
`self-test/`),
`docs/architecture/intake.md` §7.2.2.

## Problem Statement

A developer setting up a new kiss project often wants more than
the bare set of skills — they want a curated bundle that turns
kiss into a domain-aware SDD workflow (e.g. "lean" for solo work,
"self-test" for compliance-heavy environments, or a custom team
preset they author and share). Manually picking and configuring
the right combination of skills, role-agents, and command
overrides on every fresh project is repetitive and error-prone.

`kiss preset` provides:

- a discoverable list of installed and catalog presets;
- one-shot install / remove with manifest tracking;
- a priority + enable/disable model so multiple presets can
  coexist with deterministic precedence;
- a community catalog so users can share presets across teams.

Source evidence: `src/kiss_cli/cli/preset.py:79-669` (9 preset
commands + 3 catalog commands), `src/kiss_cli/presets.py:1-2098`
(manager, registry, catalog, resolver). Three bundled presets
live at `presets/lean/`, `presets/scaffold/`, `presets/self-test/`.

## User Scenarios & Testing

### User Story 1 — Install a preset (Priority: P1)

As a developer wanting a curated SDD setup, I want to run
`kiss preset add lean` and have kiss install all the skills,
role-agents, and command overrides the preset defines into my
project, with a manifest that records every file written.

**Why this priority**: This is the primary value of presets;
without it, the catalog is purely informational.

**Independent test**: Run `kiss preset add lean` in an
initialised kiss project; confirm
`.kiss/presets/registry.json` records the install and the
preset's skills appear in the AI tool's commands.

**Acceptance Scenarios**:

1. **Given** an initialised kiss project, **When** the user
   runs `kiss preset add lean`, **Then** the preset's skills
   and command overrides are installed and recorded in the
   preset registry (`cli/preset.py:129-202`).
2. **Given** the user passes a path to a local preset
   directory instead of an id, **When** the command runs,
   **Then** the preset is installed from that path
   (`cli/preset.py:129`).
3. **Given** an unknown preset id, **When** the command runs,
   **Then** the command exits with code `1` and prints an
   error.

### User Story 2 — List installed presets and browse the catalog (Priority: P1)

As a developer auditing my project's setup, I want to run
`kiss preset list` to see what is installed, and `kiss preset
catalog list` to browse the wider catalog so I can find new
useful presets.

**Acceptance Scenarios**:

1. **Given** one or more presets installed, **When** the user
   runs `kiss preset list`, **Then** the command prints a Rich
   table of installed presets with id, version, priority, and
   enabled-state columns (`cli/preset.py:95-127`).
2. **Given** any kiss project, **When** the user runs
   `kiss preset catalog list`, **Then** the command prints the
   catalog of available presets
   (`cli/preset.py:499-557`).

### User Story 3 — Remove an installed preset (Priority: P1)

As a developer who no longer needs a preset, I want to run
`kiss preset remove <id>` to delete it cleanly — preserving any
file I have modified since install (per the manifest contract).

**Acceptance Scenarios**:

1. **Given** a preset is installed, **When** the user runs
   `kiss preset remove <id>`, **Then** the preset's files are
   removed (excluding modified ones, like the integration
   manifest path) and the registry entry is dropped
   (`cli/preset.py:204-229`).

### User Story 4 — Resolve preset dependencies and conflicts (Priority: P2)

As a developer installing multiple presets, I want kiss to
resolve their relative precedence (priority + dependencies) so
that command overrides land in a deterministic order.

**Acceptance Scenarios**:

1. **Given** two presets that override the same skill, **When**
   the user runs `kiss preset resolve`, **Then** the command
   prints the effective order based on each preset's priority
   (`cli/preset.py:269-293`).
2. **Given** the same setup, **When** the user runs
   `kiss preset set-priority <id> <N>`, **Then** the priority
   is recorded and `resolve` reflects the new order
   (`cli/preset.py:367-416`).

> Note: The exact semantics of "priority" — whether it controls
> install order, override precedence, or both — are not fully
> documented. See **RDEBT-014**.

### User Story 5 — Inspect a single preset (Priority: P2)

As a developer evaluating a preset, I want to run
`kiss preset info <id>` to see its description, included
skills, and command overrides without installing it.

**Acceptance Scenarios**:

1. **Given** a known preset, **When** the user runs
   `kiss preset info <id>`, **Then** the command prints the
   preset's metadata and contents (`cli/preset.py:294-365`).
2. **Given** the preset is not installed, **When** `info` runs,
   **Then** the command shows catalog-side metadata only
   (no installed-status fields).

### User Story 6 — Search the catalog (Priority: P2)

As a developer looking for a preset matching a keyword, I want
to run `kiss preset search <query>` to filter the catalog.

**Acceptance Scenarios**:

1. **Given** the user runs `kiss preset search <q>`, **When**
   the command runs, **Then** it returns matching catalog
   entries by id / name / description
   (`cli/preset.py:231-268`).

### User Story 7 — Enable / disable an installed preset (Priority: P3)

As a developer testing a problem caused by a preset, I want to
disable it without removing it: `kiss preset disable <id>`, then
re-enable later.

**Acceptance Scenarios**:

1. **Given** a preset is installed and enabled, **When** the
   user runs `kiss preset disable <id>`, **Then** the preset's
   command overrides are temporarily inactive but its files
   remain on disk (`cli/preset.py:418-457,458-498`).
2. **Given** the same preset is disabled, **When** the user
   runs `kiss preset enable <id>`, **Then** the overrides are
   active again.

### User Story 8 — Manage the catalog (Priority: P3)

As a developer wanting to subscribe to a community catalog, I
want to run `kiss preset catalog add <name> <url-or-path>` to
register an additional source, and `kiss preset catalog remove
<name>` to drop it.

**Acceptance Scenarios**:

1. **Given** a valid catalog source, **When** the user runs
   `kiss preset catalog add <name> <src>`, **Then** the catalog
   is registered (`cli/preset.py:558-628`).
2. **Given** an existing catalog, **When** the user runs
   `kiss preset catalog remove <name>`, **Then** the catalog is
   deregistered (`cli/preset.py:629-668`).

### Edge Cases

- **`.kiss/` missing**: every preset command requires the user
  to be inside a kiss project; missing `.kiss/` exits with
  code `1` (per the manager's bootstrapping checks,
  consistent with `kiss integration` patterns).
- **Preset id and a local path collide**: `kiss preset add
  <id-or-path>` accepts both; absolute / relative paths are
  detected by existence.
- **Conflicting skill overrides between two installed presets**:
  resolution is governed by the priority order
  (`cli/preset.py:269-293`); see **RDEBT-014** for the formal
  semantics.
- **Preset compatibility errors**: surfaces via
  `PresetCompatibilityError`
  (`presets.py:283-288` per intake §7.2.2).
- **Manifest mismatch on remove**: the manager preserves
  modified files by default, mirroring integration uninstall
  behaviour. **(AI suggestion — confirm)**.
- **Catalog network access**: `kiss preset catalog add <url>`
  may require network. The bundled catalog operates offline.
  See **RDEBT-023**.
- **Catalog source signed / verified?**: trust model is
  unstated. See **RDEBT-022**.
- **Network unavailable** (offline guarantee): bundled preset
  install MUST work; community catalog refreshes are
  best-effort.

## Requirements

### Functional Requirements

- **FR-001**: The CLI MUST expose preset commands:
  `list`, `add <id-or-path>`, `remove <id>`, `search <query>`,
  `resolve`, `info <id>`, `set-priority <id> <N>`,
  `enable <id>`, `disable <id>`
  (`cli/preset.py:95,129,204,231,269,294,367,418,458`).
- **FR-002**: The CLI MUST expose catalog commands under
  `kiss preset catalog`: `list`, `add <name> <src>`,
  `remove <name>` (`cli/preset.py:499,558,629`).
- **FR-003**: All preset commands MUST verify the user is in a
  kiss project (`.kiss/` exists); missing `.kiss/` MUST exit
  with code `1`.
- **FR-004**: `add` MUST accept either a registered preset id
  (looked up via `PresetCatalog`) OR a local directory path
  containing a valid `preset.yml`
  (`cli/preset.py:129-202`).
- **FR-005**: `add` MUST validate the preset's manifest via
  `PresetManifest._validate` (raises
  `PresetValidationError` on failure)
  (`presets.py:114-270`).
- **FR-006**: `add` MUST refuse to install when a compatibility
  rule fails, raising `PresetCompatibilityError`.
- **FR-007**: `add` MUST register skill overrides and command
  registrations atomically (see ADR-014's split into
  `presets/skills.py` and `presets/commands.py` for the
  recommended structure).
- **FR-008**: `remove` MUST remove the preset's files, replay
  any skill-restore index to reinstate base skills, and update
  the registry (`presets.py:1797+` per intake §7.2.2 for the
  resolver / replay logic).
- **FR-009**: `set-priority` MUST update the registered
  priority and persist it
  (`cli/preset.py:367-416`).
- **FR-010**: `enable` / `disable` MUST flip the preset's
  active flag in the registry; disabled presets MUST not
  contribute overrides at resolve time
  (`cli/preset.py:418-498`).
- **FR-011**: `list` MUST render a Rich table of installed
  presets; `info <id>` MUST render full metadata including
  catalog source and version constraints.
- **FR-012**: `search <query>` MUST search across catalog
  entries by id / name / description.
- **FR-013**: `catalog list` MUST render every registered
  catalog and its entries; `catalog add` MUST register a new
  source; `catalog remove` MUST deregister a source.
- **FR-014**: Bundled preset install MUST NOT perform network
  I/O — assets resolve via `_locate_bundled_preset`
  (`installer.py:368-390`). Community catalog refresh may
  require network — see **RDEBT-023**.

### Non-Functional Requirements

- **NFR-001 (Offline)**: Bundled preset operations MUST not
  perform network I/O (ADR-003); community catalog operations
  are scoped separately (RDEBT-023).
- **NFR-002 (Cross-platform)**: Linux, Windows; macOS
  asserted (RDEBT-005).
- **NFR-003 (Shell parity)**: Each preset's bundled skills
  MUST ship both `scripts/bash/` and `scripts/powershell/`
  (ADR-006 / ADR-015).
- **NFR-004 (Coverage)**: ≥ 80 % on changed files
  (RDEBT-006).
- **NFR-005 (Complexity / size)**: ≤ 40 LOC, complexity ≤ 10,
  nesting ≤ 3 — current `presets.py` is 2,098 LOC and violates
  this; ADR-014 is the planned decomposition (RDEBT-007 /
  TDEBT-004).
- **NFR-006 (Lint)**: Zero Ruff warnings on changed files
  (ADR-016).
- **NFR-007 (Determinism)**: `resolve` output MUST be a pure
  function of the registry state — same registry, same
  resolution (Principle IV).
- **NFR-008 (Manifest contract)**: Every file written by `add`
  MUST be hashed in a per-preset manifest, mirroring ADR-004's
  invariant for integrations.

### Key Entities

- **`PresetManifest`** — `presets.py:114-270` (per intake
  §7.2.2). Validates the preset's `preset.yml`.
- **`PresetRegistry`** — `presets.py:271-501`. Tracks
  installed presets in `.kiss/presets/registry.json`.
- **`PresetManager`** — `presets.py:502-1482`. The
  install / remove / register orchestrator.
- **`PresetCatalog`** — `presets.py:1483-1796`. Catalog
  management.
- **`PresetResolver`** — `presets.py:1797+`. Resolves
  dependencies / precedence.
- **`PresetCatalogEntry`** — dataclass, catalog row.
- **Bundled presets**: `lean/`, `scaffold/`, `self-test/`
  (paths under repo-root `presets/`, staged into
  `core_pack/presets/` by the build hook).
- **`.kiss/presets/registry.json`** — installed-preset state.

## Success Criteria

### Measurable Outcomes

- **SC-001**: `kiss preset add <id>` followed by
  `kiss preset list` shows `<id>` as installed 100 % of the
  time across the three bundled presets.
- **SC-002**: After `kiss preset remove <id>`, every file
  recorded in the preset's install manifest is either
  removed or preserved-because-modified — never silently
  ignored.
- **SC-003**: The bundled-preset install path performs zero
  network I/O — defended by the offline test suite (extended
  per ADR-017).
- **SC-004**: `resolve` is deterministic — two runs of
  `kiss preset resolve` against the same registry produce
  byte-identical output.

## Assumptions

- The user has already run `kiss init` so `.kiss/` exists.
- Preset authors follow the schema defined by
  `PresetManifest._validate`; community presets that fail
  validation are rejected at install time.
- `priority` is an integer where lower means earlier in the
  resolution order. **(AI suggestion — confirm)** —
  see **RDEBT-014**.

## Out of Scope

- Authoring new presets (developer / contributor work; see
  `presets/template/` for the scaffold pattern).
- Migrating preset schemas across kiss versions.
- Hosting a public preset catalog server / registry.
- Verifying community-catalog signatures or reproducibility
  (the trust model is currently undefined — RDEBT-022).
- Programmatic preset application from a non-CLI entry point.

## Traceability

- **ADRs**: ADR-003 (offline), ADR-006 (parity), ADR-009
  (static integration registry — analogous principle for
  presets), ADR-014 (`presets.py` decomposition).
- **Source modules**:
  `src/kiss_cli/cli/preset.py:79-669` (12 commands);
  `src/kiss_cli/presets.py:1-2098` (manager etc.);
  `src/kiss_cli/installer.py:368-390` (bundled preset
  locator).
- **Tests**: `tests/test_presets.py`.
- **Bundled assets**: `presets/lean/preset.yml`,
  `presets/scaffold/preset.yml`,
  `presets/self-test/preset.yml`.
- **Related specs**: `extension-management/spec.md`,
  `integration-system/spec.md`, `kiss-init/spec.md` (covers
  `--preset` flag).
- **Related debts**: RDEBT-005, RDEBT-006, RDEBT-007,
  RDEBT-014 (priority semantics), RDEBT-022 (catalog trust),
  RDEBT-023 (catalog network).
