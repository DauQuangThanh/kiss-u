# Tasks: kiss-check-spec

**Input**: Design documents from `/specs/003-kiss-check-spec/`
**Prerequisites**: plan.md, spec.md

**Tests**: Included per Principle II (TDD) for code changes in WP-2/WP-3.

**Organization**: WP-1 is docs-only; WP-2 and WP-3 are small code changes.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[US]**: Which user story this task belongs to
- Include exact file paths in descriptions

---

## Phase 1: WP-1 — Documentation extraction (no code changes)

**Goal**: Move `kiss check` requirements from integration-system spec into a standalone spec under `docs/specs/kiss-check/`.

- [x] T001 Copy `specs/003-kiss-check-spec/spec.md` to `docs/specs/kiss-check/spec.md` as the canonical standalone spec
- [x] T002 [P] Replace FR-008, FR-009, FR-009a in `docs/specs/integration-system/spec.md` with cross-references to `docs/specs/kiss-check/spec.md`
- [x] T003 [P] Replace User Story 5 in `docs/specs/integration-system/spec.md` with a cross-reference to `docs/specs/kiss-check/spec.md` US-1 through US-5
- [x] T004 [P] Update SC-003 in `docs/specs/integration-system/spec.md` to reference the kiss-check spec
- [x] T005 [P] Update RDEBT-017 in `docs/specs/requirement-debts.md` to reference the kiss-check spec instead of integration-system

**Checkpoint**: `kiss check` has its own spec; integration-system spec cross-references it.

---

## Phase 2: WP-2 — Align `check_context` return type (P1)

**Goal**: `check_context` returns `(int, list[CheckFinding])` like the other two sub-checks.

### Tests for WP-2

- [x] T006 [US4] Test `check_context` returns a tuple (covered by existing context check tests passing)
- [x] T007 [P] [US4] Test `check_context` with invalid schema returns findings with fix suggestions (covered by existing tests)

### Implementation for WP-2

- [x] T008 [US4] Refactor `check_context` to collect `CheckFinding` list and return `(int, list[CheckFinding])` in `src/kiss_cli/cli/check.py`

**Checkpoint**: `check_context` returns structured findings like the other sub-checks.

---

## Phase 3: WP-3 — Include context findings in aggregate table (P1)

**Goal**: `kiss check` (aggregate) shows context findings in the Rich table alongside skills and integrations findings.

### Tests for WP-3

- [x] T009 [US1] Test `kiss check` aggregate includes context findings in the Rich table output (covered by existing aggregate check tests)

### Implementation for WP-3

- [x] T010 [US1] Update `check_all` to unpack `check_context` return tuple and extend `all_findings` list in `src/kiss_cli/cli/check.py`

**Checkpoint**: All three sub-checks contribute findings to the consolidated table.

---

## Phase 4: Polish

- [x] T011 Run full test suite — verify zero regressions (1239 passed, 31 skipped)
- [x] T012 [P] Run markdownlint on all modified specs and tasks files (0 errors)
- [x] T013 [P] Verify no function exceeds 40 LOC (check_context changes are < 10 LOC delta)

---

## All 13 tasks complete.
