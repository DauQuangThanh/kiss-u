<!--
Sync Impact Report
==================
Version change: (none) → 1.0.0
Reason: Initial ratification of project standards. Theme: code simplicity and testability.

Principles introduced:
  - I. Simplicity First (KISS / YAGNI)
  - II. Test-First (NON-NEGOTIABLE)
  - III. Small, Focused Units
  - IV. Pure & Deterministic by Default
  - V. Continuous Refactoring

Sections added:
  - Quality Gates
  - Development Workflow
  - Governance

Sections removed: (none)

Templates requiring updates:
  - ✅ docs/standards.md (this file) — created from agent-skills/kiss-standardize/templates/standard-template.md
  - ⚠ agent-skills/kiss-standardize/templates/plan-template.md — no Standards Check block today; add one when /kiss-plan runs against a feature
  - ⚠ agent-skills/kiss-standardize/templates/spec-template.md — confirm scope/requirements references on first /kiss-specify run
  - ⚠ agent-skills/kiss-standardize/templates/task-template.md — confirm task categories include "tests-first" tasks on first /kiss-taskify run

Follow-up TODOs: (none)
-->

# KISS Standards

## Core Principles

### I. Simplicity First (KISS / YAGNI)

Every change MUST take the simplest path that satisfies the stated requirement.

- Do **not** add features, abstractions, configuration knobs, or generality that no current requirement asks for.
- A new abstraction (helper, layer, framework) MUST justify itself against at least two existing concrete call sites before it ships.
- Three similar lines is acceptable; a premature abstraction is not.
- Dead code, unused parameters, unused exports, and "just in case" branches MUST be removed in the same change that orphans them.

**Rationale**: Simpler code is easier to read, easier to test, and cheaper to change. Optionality has a real carrying cost (review burden, test surface, security surface) and SHOULD be paid only when the project genuinely needs it.

### II. Test-First (NON-NEGOTIABLE)

Strict Test-Driven Development applies to all production code paths.

- Tests MUST be written **before** the implementation. The required cycle is **Red → Green → Refactor**:
  1. Write a failing test that captures the next slice of behaviour.
  2. Run it; confirm it fails for the expected reason.
  3. Write the smallest implementation that makes the test pass.
  4. Refactor under green.
- Pull requests that introduce production code without a corresponding new test in the same diff MUST be rejected at review.
- Bash and PowerShell scripts have parity per CLAUDE.md; tests MUST cover both flavours when both ship.
- Bug fixes MUST add a regression test that fails before the fix and passes after — the test goes in the same commit as the fix.

**Rationale**: Writing tests first keeps the code testable by construction, surfaces design problems before they calcify, and gives every change a tripwire. Loosening this rule creates untested code paths the project never recovers; we accept the upfront friction in exchange for that floor.

### III. Small, Focused Units

Functions, classes, and modules MUST stay small and single-purpose.

- A function SHOULD fit on one screen (≈ 40 lines of executable code) and SHOULD have cyclomatic complexity ≤ 10.
- A function MUST do one thing. If you need the word "and" to describe it, split it.
- A module's public surface MUST be the smallest set of names that lets callers do their job; everything else stays private.
- Nesting depth in any function SHOULD be ≤ 3 levels; deeper nesting is a refactor signal.

**Rationale**: Small units are individually testable, individually replaceable, and individually understandable. Complexity caps are mechanical proxies for "this is getting hard to reason about" — they exist so reviewers have a non-political reason to ask for a split.

### IV. Pure & Deterministic by Default

Business logic MUST be expressed as pure, deterministic functions; side-effects MUST be isolated at the edges.

- Functions that take inputs and return outputs MUST NOT also read from or write to globals, the filesystem, the network, the clock, or random sources unless that side-effect is the function's stated job.
- I/O, time, randomness, and process state MUST be injected (parameter, constructor argument, or interface) rather than reached for via globals — this keeps tests fast and deterministic.
- Functions whose behaviour depends on time, randomness, or environment MUST accept a clock / RNG / config object so tests can substitute fakes.
- Shared mutable state across modules is forbidden unless explicitly justified and documented.

**Rationale**: Pure functions are trivially testable: same inputs, same outputs, no setup. Side-effect leakage is the single largest source of flaky tests, so the principle pays its dues directly to Principle II.

### V. Continuous Refactoring

Every change MUST leave the touched code at least as simple as it was found.

- Every PR MUST run under green tests; refactors MUST NOT be merged on red.
- Any new complexity (an added abstraction, a new dependency, a new configuration knob, a function exceeding the limits in Principle III) MUST be justified in the PR description with the concrete requirement that demanded it.
- TODO / FIXME comments MUST link to a tracked issue and MUST NOT accumulate as the canonical record of debt — that is what `docs/tech-debts.md` and `docs/test-debts.md` are for.
- Dead code, commented-out code, and obsolete feature flags MUST be deleted, not preserved "just in case" — git history is the archive.

**Rationale**: Codebases rot when nobody is allowed to clean as they go. Mandating that each PR is a small improvement (or at worst, neutral) keeps debt from compounding silently between dedicated cleanup sprints that never actually get scheduled.

## Quality Gates

These gates MUST pass for a change to merge to `main`. CI enforces them; reviewers verify them.

- **Tests**: full test suite passes on every supported platform (macOS, Linux, Windows) and every supported shell (Bash, PowerShell).
- **Coverage**: line coverage on changed files MUST be ≥ 80%. Coverage gaps MUST be explained in the PR description, not silently accepted.
- **Complexity**: no function in the diff may exceed cyclomatic complexity 10 or 40 executable lines without an explicit waiver in the PR description.
- **Lint / format**: linters and formatters MUST pass with zero warnings on changed files. Markdown files MUST pass markdown lint per CLAUDE.md.
- **Parity**: any change to a Bash script MUST be mirrored in the equivalent PowerShell script (and vice versa) in the same PR.
- **Public API**: public-API changes (CLI flags, exported functions, config schema) MUST update the corresponding tests and any user-facing documentation in the same PR.

## Development Workflow

- **Branching**: features are developed on branches created via `/kiss-git-feature`; commits land via `/kiss-git-commit`. Direct pushes to `main` are forbidden.
- **TDD cadence per task**: pick the smallest next behaviour → write the failing test → make it pass → refactor → commit. Do not batch multiple Red-Green cycles into one commit when they can ship separately.
- **Code review**: every PR MUST be reviewed by at least one human before merge. Reviewers verify (a) the tests actually exercise the new behaviour, (b) the change respects Principles I–V, and (c) the Quality Gates hold.
- **Bug fixes**: every fix MUST start with a regression test (Principle II) and MUST be recorded in `docs/bugs/` per project conventions.
- **Parity discipline**: contributions touching `scripts/bash/` or `scripts/powershell/` keep both flavours in sync per CLAUDE.md; the PR description MUST call out parity explicitly.
- **Refactor with intent**: behaviour-preserving refactors ship as separate PRs from behaviour changes. They MUST NOT modify tests except to keep them compiling.

## Governance

- **Authority**: This document supersedes ad-hoc team practices. Where this document and another guide disagree, this document wins until amended.
- **Amendment procedure**: Changes are proposed via PR editing this file. The PR MUST include (a) a Sync Impact Report at the top of the file, (b) the rationale for the change, and (c) any updates required in dependent templates (`agent-skills/kiss-standardize/templates/*.md`, `CLAUDE.md`, `AGENTS.md`, runtime guidance docs).
- **Versioning** follows semantic versioning:
  - **MAJOR** — a principle is removed, redefined, or weakened in a way existing code may now violate.
  - **MINOR** — a new principle or section is added, or an existing one is materially expanded.
  - **PATCH** — wording, formatting, typo, or clarifying-rationale changes that do not alter rules.
- **Compliance review**: PR reviewers MUST verify the change complies with all principles. Any explicit deviation MUST be justified in the PR description and recorded as a debt entry (`docs/tech-debts.md`, `docs/test-debts.md`, etc.) so the project does not lose track of waivers.
- **Runtime guidance**: For day-to-day instructions to AI assistants and humans, see `CLAUDE.md` and `AGENTS.md`. Those files MUST stay consistent with the principles defined here.

**Version**: 1.0.0 | **Ratified**: 2026-04-26 | **Last Amended**: 2026-04-26
