# Feature Specification: narrow-to-seven-ais

**Feature Slug**: `narrow-to-seven-ais`
**Created**: 2026-04-26
**Status**: Draft
**Branch**: `004-narrow-to-seven-ais`

## Problem Statement

The kiss codebase ships 13 AI integration packages but only 7 are
supported per `docs/AI-urls.md` and ADR-018. The 6 unsupported
integrations (`agy`, `auggie`, `generic`, `kilocode`, `kiro_cli`,
`tabnine`) add dead code, confuse the `kiss init` picker, inflate
the wheel, and cause test/maintenance overhead. Additionally:

- Asset integrity verification (`_integrity.verify_asset_integrity`)
  is defined but never wired into the runtime (RDEBT-003).
- Subagent per-AI rendering is unverified (RDEBT-027).

This feature removes all unsupported integrations from source,
tests, docs, and catalog, then wires asset integrity and verifies
the subagent install paths.

## Supported AIs (authoritative list from `docs/AI-urls.md`)

1. **Claude Code** (`claude`) — Agent file: `CLAUDE.md`
2. **GitHub Copilot** (`copilot`) — Agent file: `AGENTS.md`
3. **Cursor Agent** (`cursor-agent`) — Agent file: `AGENTS.md`
4. **OpenCode** (`opencode`) — Agent file: `AGENTS.md`
5. **Windsurf** (`windsurf`) — Agent file: `AGENTS.md`
6. **Gemini CLI** (`gemini`) — Agent file: `GEMINI.md`
7. **Codex** (`codex`) — Agent file: `AGENTS.md`

## To Remove

`agy`, `auggie`, `generic`, `kilocode`, `kiro_cli` (key:
`kiro-cli`), `tabnine` — from source packages, registry, catalog,
tests, and documentation references.

## User Stories

### US-1: Remove unsupported integration packages (Priority: P1)

As a maintainer, I want the 6 unsupported integration packages
removed from `src/kiss_cli/integrations/` so the codebase only
contains supported code.

**Acceptance Scenarios**:

1. **Given** the codebase, **When** I list
   `src/kiss_cli/integrations/`, **Then** only `claude/`,
   `codex/`, `copilot/`, `cursor_agent/`, `gemini/`,
   `opencode/`, `windsurf/` (plus `__init__.py`, `base.py`,
   `manifest.py`, `catalog.py`) exist.
2. **Given** the registry, **When** I import
   `kiss_cli.integrations`, **Then** `INTEGRATION_REGISTRY`
   contains exactly 7 keys.

### US-2: Remove unsupported integration tests (Priority: P1)

As a maintainer, I want test files for removed integrations
deleted so CI doesn't run dead tests.

**Acceptance Scenarios**:

1. **Given** `tests/integrations/`, **When** I list it,
   **Then** `test_integration_agy.py`, `test_integration_auggie.py`,
   `test_integration_generic.py`, `test_integration_kilocode.py`,
   `test_integration_kiro_cli.py`, `test_integration_tabnine.py`
   do not exist.
2. **Given** remaining test files, **When** they reference
   removed integrations, **Then** those references are updated
   or removed.

### US-3: Clean catalog and documentation (Priority: P1)

As a maintainer, I want `integrations/catalog.json` and all doc
files to only reference the 7 supported AIs.

**Acceptance Scenarios**:

1. **Given** `integrations/catalog.json`, **When** parsed,
   **Then** it contains exactly 7 entries.
2. **Given** doc files, **When** they mention removed
   integrations, **Then** those mentions are removed or marked
   as historical.

### US-4: Wire asset integrity verification (Priority: P2)

As a security-conscious user, I want `kiss init` and
`kiss integration upgrade` to call
`verify_asset_integrity(core_pack_root)` before reading the
bundle, so tampered wheels are detected.

**Acceptance Scenarios**:

1. **Given** an intact wheel, **When** `kiss init` runs,
   **Then** `verify_asset_integrity` is called and returns
   success.
2. **Given** a tampered asset, **When** `kiss init` runs,
   **Then** `AssetCorruptionError` is raised and the command
   aborts.

### US-5: Clean up source references (Priority: P1)

As a maintainer, I want all source files that reference removed
integrations (AGENT_CONFIG, check.py INTEGRATION_INSTALL_DIRS,
installer.py kiro-cli special case, etc.) updated.

**Acceptance Scenarios**:

1. **Given** the source tree, **When** I grep for
   `agy|auggie|kilocode|kiro|tabnine|generic`, **Then** no
   hits in `src/kiss_cli/` (except comments explaining the
   removal).

## Functional Requirements

- **FR-001**: Remove integration packages: `agy/`, `auggie/`,
  `generic/`, `kilocode/`, `kiro_cli/`, `tabnine/`.
- **FR-002**: Update `_register_builtins()` to register only the
  7 supported integrations.
- **FR-003**: Remove test files for the 6 removed integrations.
- **FR-004**: Update `integrations/catalog.json` to contain only
  7 entries.
- **FR-005**: Remove `kiro-cli` special case from
  `installer.py:check_tool`.
- **FR-006**: Remove removed integrations from
  `check.py:INTEGRATION_INSTALL_DIRS`.
- **FR-007**: Remove `tabnine` from `_TOML_AGENTS` in
  `__init__.py`.
- **FR-008**: Update remaining test files that reference removed
  integrations.
- **FR-009**: Wire `verify_asset_integrity` into `kiss init` and
  `kiss integration upgrade` (RDEBT-003).
- **FR-010**: Update all doc files to remove references to
  removed integrations or mark them as historical (ADR-018).
- **FR-011**: Resolve RDEBT-024 (spec/code divergence) and
  RDEBT-004 (count discrepancy) as completed.

## Non-Functional Requirements

- **NFR-001**: All existing tests for supported integrations MUST
  continue to pass.
- **NFR-002**: The wheel size MUST decrease (fewer packages).
- **NFR-003**: `kiss init` picker MUST show exactly 7 choices.

## Success Criteria

- **SC-001**: `INTEGRATION_REGISTRY` contains exactly 7 keys.
- **SC-002**: `grep -r "agy\|auggie\|kilocode\|kiro\|tabnine"
  src/kiss_cli/` returns zero hits (excluding comments).
- **SC-003**: All tests pass with zero regressions.
- **SC-004**: `verify_asset_integrity` is called during
  `kiss init`.

## Out of Scope

- Subagent per-AI rendering verification (RDEBT-027) — separate
  feature.
- Skill renames (RDEBT-031) — separate feature.

## Traceability

- **Resolves**: RDEBT-003, RDEBT-004, RDEBT-024, TDEBT-028
- **ADRs**: ADR-018 (narrow integration scope)
