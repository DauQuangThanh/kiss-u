# Implementation Plan: kiss-check standalone spec

**Branch**: `003-kiss-check-spec` | **Date**: 2026-04-26 | **Spec**: [spec.md](spec.md)

## Summary

Extract `kiss check` from the integration-system spec into its own
standalone feature specification. The implementation work is
primarily documentation — moving acceptance criteria, updating
cross-references, and ensuring the existing `cli/check.py` code
aligns with the new spec. The `check_context` function also needs
a minor refactor to return `(exit_code, findings)` tuples like
the other two sub-checks (partially done in WP-7 of feature 001).

## Technical Context

**Language/Version**: Python 3.11+
**Source file**: `src/kiss_cli/cli/check.py` (685 LOC)
**Testing**: pytest, existing tests in `tests/test_check_command.py`
**Constraints**: Read-only refactoring — no behavior changes to the check command itself

## Standards Check

| Gate | Status | Notes |
|------|--------|-------|
| Test-First (Principle II) | PASS | Existing tests cover check behavior |
| Small Units (Principle III) | WATCH | `check_context` is 190 LOC — candidate for extraction |
| Coverage ≥ 80% | PASS | Existing coverage maintained |

## Work Packages

### WP-1: Spec documentation (no code changes)

1. Create `docs/specs/kiss-check/spec.md` (the standalone spec —
   already drafted as this feature's `spec.md`).
2. Update `docs/specs/integration-system/spec.md` to cross-
   reference the new spec instead of defining check requirements
   inline.
3. Move FR-008, FR-009, FR-009a from integration-system spec to
   the kiss-check spec (replace with cross-references).

### WP-2: Align `check_context` return type

`check_skills` and `check_integrations` already return
`(exit_code, findings)` tuples (from feature 001 WP-7).
`check_context` still returns `int`. Align it to also return
`(int, list[CheckFinding])` so the aggregate check can include
context findings in the Rich table.

### WP-3: Add `check_context` findings to aggregate table

After WP-2, update `check_all` to collect context findings and
include them in the consolidated Rich table.

## Dependency Graph

```text
WP-1 (docs) ── independent
WP-2 (check_context return type) → WP-3 (aggregate table)
```

WP-1 is pure documentation; WP-2 + WP-3 are code changes.

## Risk Register

| Risk | Impact | Mitigation |
|------|--------|------------|
| check_context refactor breaks existing tests | Medium | TDD — write return-type tests first |
| Cross-reference update in integration-system spec is incomplete | Low | Grep for FR-008/FR-009 across all specs |
