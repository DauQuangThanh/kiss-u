# ADR-015: Promote Bash/PowerShell parity to an architectural invariant

**Date:** 2026-04-26
**Status:** Proposed
**Decider:** (decider: TBD — confirm)

## Context

ADR-006 records that every skill ships both Bash and PowerShell
flavours. Today the rule is:

- Mandated by team practice (`CLAUDE.md` "Cross-platform shells",
  `docs/standards.md` Quality Gates → "Parity").
- Encoded in the per-skill folder layout (the `_template/`
  scaffolding in `agent-skills/_template/scripts/{bash,powershell}/`
  is what `kiss init` expects).
- Tested at the integration / install level by the Ubuntu +
  Windows CI matrix
  (`.github/workflows/test.yml:30-55`).

What is missing:

- A **mechanical parity test** that, for every Bash script in the
  shipped skills, asserts an equivalent PowerShell script exists
  with the same set of public commands / flag names, and vice
  versa. (TDEBT-021)
- A clear architectural statement that "parity" is not a
  preference but an invariant, so a future contribution adding a
  Bash-only skill is rejected at review.

## Decision

Bash / PowerShell parity is an **architectural invariant** of
KISS, with three concrete commitments:

1. **Folder discipline** — every skill that ships scripts has the
   layout
   `agent-skills/kiss-<name>/scripts/{bash,powershell}/` with a
   matching set of script files.
2. **Argument parity** — Bash and PowerShell scripts accept the
   same argument names. The mode flag is `--auto` (Bash) /
   `-Auto` (PowerShell) (per ADR-012), and other flags are
   identical strings.
3. **Mechanical parity test** (TDEBT-021) — a test under
   `tests/` walks every `agent-skills/kiss-<name>/scripts/bash/`
   directory, asserts a sibling `powershell/` exists with the
   same set of script names (after the `.sh`/`.ps1` swap), and
   does the inverse walk. The test fails CI if a contributor
   adds a one-shell-only script.

Adding new functionality MUST land both flavours in the same PR
(`docs/standards.md` Quality Gates → "Parity"). The mechanical
test makes that gate enforceable instead of cultural.

## Consequences

- (+) Cross-platform support stops being an emergent property of
  reviewer attention and becomes a CI gate.
- (+) Contributors get fast feedback when they forget the
  PowerShell flavour.
- (+) The architectural statement makes "we don't ship
  Bash-only" non-negotiable in code review.
- (−) Doubles the script surface area and requires every Bash
  change to have a tested PowerShell counterpart.
- (−) The mechanical parity test only checks *file presence and
  argument names*, not *semantic equivalence*. Semantic drift
  (a Bash script writing one path, the PowerShell writing
  another) still requires reviewer attention.

## Alternatives considered

- **Drop parity, document Bash-only** — rejected; locks out
  Windows-first developers.
- **Use only Python scripts (no shell)** — rejected; many skill
  scripts are thin wrappers around `sed` / `grep` / `find` and
  re-implementing them in Python is an over-engineering tax.
- **Accept manual parity (no mechanical test)** — current state.
  Rejected — Quality Gates need automation.

## Source evidence

- `docs/standards.md` Quality Gates → "Parity"
- `CLAUDE.md` "Cross-platform shells"
- `agent-skills/_template/scripts/`
- `src/kiss_cli/skill_assets.py:1-23,79-127`
- ADR-006 (originating decision); this ADR is the architectural
  promotion + parity-test commitment.
