# Feature Specification: kiss-check

**Feature Slug**: `kiss-check`
**Created**: 2026-04-26
**Status**: Draft
**Branch**: `003-kiss-check-spec`

## Problem Statement

`kiss check` is a cross-cutting diagnostic tool that validates
skills, integrations, and context configuration. It currently
lives as User Story 5 + FR-008/FR-009/FR-009a inside
`docs/specs/integration-system/spec.md`, even though it validates
concerns owned by three different specs (agent-skills-system,
integration-system, and the context.yml schema).

This creates two problems:

1. A developer implementing the skills system would not know that
   `kiss check skills` has acceptance criteria — they'd have to
   read the integration-system spec to find them.
2. The check command's output format, exit code semantics, and
   findings model (`CheckFinding`) are shared infrastructure that
   doesn't belong to any one feature.

This spec extracts `kiss check` into its own feature so each
sub-check's acceptance criteria, output format, and validation
rules are documented in one place.

## Source

Extracted from:

- `docs/specs/integration-system/spec.md` — User Story 5,
  FR-008, FR-009, FR-009a, SC-003, RDEBT-017
- `src/kiss_cli/cli/check.py` (685 LOC) — existing implementation

## User Stories

### US-1: Run all checks at once (Priority: P1)

As a user troubleshooting a project, I want to run `kiss check`
and see a single report covering skills, integrations, and
context — with all findings shown and a suggested fix for each.

**Acceptance Scenarios**:

1. **Given** any kiss project, **When** the user runs
   `kiss check`, **Then** all three sub-checks run to completion,
   findings are rendered in a Rich table grouped by sub-check
   (columns: File, Check, Issue, Suggested Fix), and the exit
   code is the maximum of the three sub-check codes.
2. **Given** a healthy project, **When** the user runs
   `kiss check`, **Then** the output shows "ALL CHECKS PASSED"
   and exits with code `0`.

### US-2: Check skills only (Priority: P1)

As a user who suspects a broken skill file, I want to run
`kiss check skills` to validate every installed SKILL.md against
the agentskills.io schema.

**Acceptance Scenarios**:

1. **Given** a valid skill installation, **When** the user runs
   `kiss check skills`, **Then** each skill is validated and
   the summary shows `Skills: N/N passed`.
2. **Given** a skill with missing `description` frontmatter,
   **When** the user runs `kiss check skills`, **Then** the
   finding shows the file, the issue, and a suggested fix
   (`kiss integration upgrade <key> --force`).

### US-3: Check integrations only (Priority: P1)

As a user who wants to verify integration directories exist,
I want to run `kiss check integrations` to confirm each
installed integration has its expected directory tree.

**Acceptance Scenarios**:

1. **Given** all integration directories exist, **When** the
   user runs `kiss check integrations`, **Then** the output
   shows "Integrations: OK".
2. **Given** an orphaned directory, **When** the user runs
   `kiss check integrations`, **Then** the finding reports
   the orphan with a suggested fix.

### US-4: Check context only (Priority: P1)

As a user who edited `.kiss/context.yml` manually, I want to
run `kiss check context` to validate the schema is well-formed.

**Acceptance Scenarios**:

1. **Given** a valid context.yml, **When** the user runs
   `kiss check context`, **Then** the output shows
   "Context: OK".
2. **Given** a context.yml with an invalid `schema_version`,
   **When** the user runs `kiss check context`, **Then** the
   finding reports the issue.

### US-5: Actionable fix suggestions (Priority: P2)

As a user who sees a check failure, I want each finding to
include a concrete command I can run to fix the problem, so I
don't have to guess what to do next.

**Acceptance Scenarios**:

1. **Given** any check finding, **When** it is rendered,
   **Then** the `Suggested Fix` column contains a runnable
   `kiss` command or a clear manual action.

## Functional Requirements

- **FR-001**: The CLI MUST expose `kiss check` with sub-commands
  `skills`, `integrations`, and `context`.
- **FR-002**: When invoked without a sub-command, `kiss check`
  MUST run all three sub-checks in sequence and render a
  consolidated report.
- **FR-003**: The aggregate exit code MUST be the maximum of the
  three sub-check exit codes (`0` = all pass, `1` = at least
  one failure).
- **FR-004**: Each sub-check MUST run to completion and collect
  all findings — never stop at the first failure.
- **FR-005**: Findings MUST be rendered in a Rich table with
  columns: File, Check, Issue, Suggested Fix.
- **FR-006**: `check skills` MUST read the installed integrations
  list from `integration.json` (via `_read_integration_json`),
  falling back to `init-options.json`.
- **FR-007**: `check integrations` MUST verify each integration's
  install directory exists and detect orphaned directories.
- **FR-008**: `check context` MUST validate `.kiss/context.yml`
  against the documented schema (schema_version, paths, current,
  preferences, language, integrations).
- **FR-009**: Each finding MUST include a concrete fix suggestion
  (a runnable `kiss` command or a manual action).

## Non-Functional Requirements

- **NFR-001**: `kiss check` MUST NOT perform network I/O.
- **NFR-002**: All check functions MUST be testable in isolation
  (accept `project_root` parameter, no global state).
- **NFR-003**: Changed files MUST maintain ≥ 80% coverage.

## Success Criteria

- **SC-001**: `kiss check` exits `0` on every freshly-initialized
  project for all seven supported integrations.
- **SC-002**: Every check finding includes a non-empty fix
  suggestion.
- **SC-003**: `check context` detects and reports all schema
  violations in a single run.

## Out of Scope

- Fixing detected issues automatically (check is read-only).
- Checking the external AI CLI availability (covered by
  `kiss init`'s precheck).
- Manifest integrity verification (covered by RDEBT-003).

## Traceability

- **Extracted from**: `integration-system/spec.md` US-5,
  FR-008, FR-009, FR-009a
- **Source**: `src/kiss_cli/cli/check.py`
- **Related debts**: RDEBT-017 (exit code "max" semantics)
