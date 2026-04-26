# Architect — Auto-mode Decision Log

**Date:** 2026-04-26
**Agent:** `architect`
**Mode:** `auto` (user instructed "in auto mode" in their first message)

> One entry per non-trivial decision the agent took on the user's
> behalf during this run. Trivial choices (artefact wording,
> formatting) are not logged. Decision kinds:
> `default-applied` (a required input was missing and a default was
> used), `alternative-picked` (≥ 2 viable options, no question
> asked), `autonomous-action` (wrote an artefact the user did not
> explicitly request), `debt-overridden` (proceeded past a flagged
> debt on user say-so).
>
> Decisions and debts are separate: every entry below is a
> **resolved** choice the agent made; the *unresolved* questions
> live in `docs/architecture/tech-debts.md` as `TDEBT-NNN`.

## Decisions

### D-001 (default-applied) — Quality-attribute ranking

- **Context:** The user did not specify a quality-attribute
  ranking; the architecture intake template requires one.
- **Default applied:** Cross-platform parity (1) > install-time
  correctness (2) > offline-first (3) > simplicity-of-output (4)
  > maintainability (5), with performance (6) and security-of-
  installed-tree (7) tracked but not in the top 5.
- **Why this default:** `docs/standards.md` Quality Gates makes
  cross-platform support the first hard gate; ADR-004 / ADR-007
  show install-time integrity is the next-most-defended property;
  ADR-003 protects offline-after-install via tests; Principle I
  (KISS) drives output simplicity; maintainability is the
  weakest attribute today (`extensions.py`, `presets.py`).
- **Recorded in:** `docs/architecture/intake.md` §1.

### D-002 (alternative-picked) — `extensions/` package layout

- **Context:** Multiple decompositions of `extensions.py` are
  reasonable: by class (one module per class), by feature
  (install / remove / list across modules), or by side-effect
  type (pure / file-I/O / subprocess).
- **Picked:** Side-effect-type split. Pure helpers (`errors.py`,
  `version.py`, `frontmatter.py`) separate from filesystem-I/O
  modules separate from the single subprocess-calling module
  (`hooks.py`).
- **Why:** Maximises Principle IV testability — pure helpers can
  be tested without filesystem fakes. Other splits leave
  side-effects mixed inside per-class modules.
- **Recorded in:** `docs/decisions/ADR-013-decompose-extensions-py.md` §Decision.

### D-003 (alternative-picked) — `presets/` package layout

- **Context:** Same trade-space as D-002.
- **Picked:** Symmetric side-effect-type split mirroring D-002.
- **Why:** Two parallel packages with the same shape reduce
  cognitive load for contributors; resolver can stay pure.
- **Recorded in:** `docs/decisions/ADR-014-decompose-presets-py.md`.

### D-004 (alternative-picked) — Public class names preserved during decomposition

- **Context:** Decomposition could either rename classes
  (e.g. `ExtensionManager` → `Manager`) for cleanness inside the
  new package, or preserve them via re-export from
  `__init__.py`.
- **Picked:** Preserve names. Facade re-exports from
  `extensions/__init__.py` and `presets/__init__.py` keep
  callers (`cli/extension.py`, `cli/preset.py`, `cli/init.py`)
  working unchanged.
- **Why:** Principle V — refactor must leave touched code at
  least as simple. Renaming would force breaking changes on
  every importer at the same time as a structural refactor;
  too much risk in one cycle.
- **Recorded in:** ADR-013, ADR-014.

### D-005 (alternative-picked) — Decompose by multiple PRs, not one big PR

- **Context:** ADR-013 and ADR-014 could land as one PR each or
  as a sequence (PR-A through PR-F).
- **Picked:** Multiple sequential PRs per ADR.
- **Why:** Principle II (test-first) and Principle V (refactor
  leaves code at least as simple) are easier to honour in
  reviewable chunks. A 2,500-line refactor is unreviewable.
- **Recorded in:** ADR-013 §Decision, ADR-014 §Decision.

### D-006 (alternative-picked) — Ruff lint + format over Ruff+Black or Flake8 stack

- **Context:** ADR-016 must pick between Ruff-only, Ruff+Black,
  Flake8+Black+isort+mccabe, or Pylint.
- **Picked:** Ruff lint + format (Candidate A in
  `docs/research/python-lint-format-toolchain.md`).
- **Why:** Already in CI; one tool covers Pyflakes / pycodestyle /
  isort / pyupgrade / bugbear / mccabe (cyclomatic ≤ 10 enforced
  natively per Principle III); zero new dev-deps; fastest on
  cross-platform CI; explicit `[tool.ruff]` block satisfies the
  "lint zero warnings" gate in `docs/standards.md`.
- **Status:** **Recommendation only.** ADR-016 is `Proposed` with
  Decider TBD; the human decider can flip to a different
  candidate without invalidating this log.
- **Recorded in:** ADR-016, research note.

### D-007 (alternative-picked) — Promote 12 candidate ADRs as separate `Proposed` files (not consolidated)

- **Context:** The technical-analyst's CADR-001…012 could be
  written as one combined ADR ("ratify the existing
  architecture") or as 12 separate ADRs.
- **Picked:** 12 separate ADR files under `docs/decisions/`.
- **Why:** Michael Nygard ADR convention (one decision per file);
  enables independent acceptance per topic; future supersession
  is cleaner.
- **Recorded in:** `docs/decisions/ADR-001-…` through
  `ADR-012-…`.

### D-008 (autonomous-action) — Wrote `tech-debts.md` with 27 TDEBT entries

- **Context:** The user instructed to "log every TDEBT entry";
  `docs/architecture/tech-debts.md` did not exist.
- **Action:** Created the file with the status legend and the
  27 entries surfaced during this re-design.
- **Why:** Required by the user prompt; required by the architect
  agent's prompt; debts must be tracked separately from
  resolved decisions.
- **Recorded in:** `docs/architecture/tech-debts.md`.

### D-009 (autonomous-action) — Wrote `docs/research/python-lint-format-toolchain.md`

- **Context:** The user prompt said tech-research is "generally
  not needed here — the stack is already chosen — but use it for
  any *new* decision the re-design opens (e.g. lint tool
  choice)". ADR-016 introduces a new decision area, so the
  research note is justified.
- **Action:** Wrote the research note backing ADR-016 with four
  candidates and per-candidate trade-offs. Marked vendor / version
  / licence claims `(unverified — confirm)` and logged TDEBT-025
  through TDEBT-027.
- **Why:** ADR-016 references the research; without the research
  note the ADR's "Alternatives considered" section would be
  unsourced.
- **Recorded in:** `docs/research/python-lint-format-toolchain.md`.

### D-010 (default-applied) — Decider field for every ADR

- **Context:** No decider is named anywhere in the prompt or in
  `.kiss/context.yml`.
- **Default applied:** `(decider: TBD — confirm)` on all 17
  ADRs. Status: `Proposed` on all 17.
- **Why:** The architect agent never decides on a human's
  behalf (per its own prompt: "the AI is never the decider").
- **Recorded in:** Every `docs/decisions/ADR-*.md`.

### D-011 (alternative-picked) — Sizing target ≤ 400 LOC per module

- **Context:** Principle III caps **functions** at ≤ 40
  executable LOC and cyclomatic ≤ 10, but does not give a
  module-size cap.
- **Picked:** ≤ 400 LOC per module as a soft target for the
  `extensions/` and `presets/` decomposition (10× the function
  cap, picked to make per-module review feasible on one screen
  scroll).
- **Why:** Mechanical proxy for "single-purpose module"; if a
  module grows past 400 LOC during a PR, that's a visible signal
  to split again. Not a hard rule.
- **Recorded in:** ADR-013, ADR-014, `c4-component.md`.

### D-012 (alternative-picked) — Asset integrity check at start of `kiss init` (ADR-007)

- **Context:** `_integrity.verify_asset_integrity` could be
  invoked at: import time (whenever `kiss_cli` loads), at start
  of every subcommand, only at start of `init` / `upgrade`, or
  on demand.
- **Picked:** Start of `init` and `upgrade` (write-path
  subcommands).
- **Why:** Read-only subcommands like `version` and `check
  context` shouldn't pay the hash cost; corruption that affects
  read-only paths is detected on the next write-path
  invocation, which is the natural recovery point. Avoids
  Principle I violation (over-eager checking).
- **Recorded in:** ADR-007 §Decision.

### D-013 (autonomous-action) — Surfaced container-level invariants in `c4-container.md`

- **Context:** The C4 Level-2 template asks for containers and a
  communication matrix; the user prompt asked for the
  decomposition focus to be in Level 3, but the offline-runtime,
  parity, integrity, hashed-write, and static-registry
  invariants logically belong at the container level.
- **Action:** Added an "Architectural invariants" subsection to
  `c4-container.md` listing five invariants and pointing each
  to its ADR.
- **Why:** Without the invariants written down at the container
  level, a future contribution at the container boundary
  (e.g. "let's add a network refresh step") would have no
  Level-2 anchor for the rejection at review.
- **Recorded in:** `docs/architecture/c4-container.md` §"Architectural invariants".

## Notes

- All choices above are **defaults / recommendations**, not
  binding decisions. Every ADR's Decider field stays
  `(decider: TBD — confirm)` and Status stays `Proposed` until a
  human accepts.
- Source code under `src/` and `pyproject.toml` were **not
  modified** by this run. Only files under `docs/` were written.
