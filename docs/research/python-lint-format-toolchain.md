<!-- markdownlint-disable MD024 -->
# Research: Python lint + format toolchain

**Date:** 2026-04-26
**Constraints considered:** see `docs/architecture/intake.md`,
particularly Quality Gates "Lint zero warnings" and Principle III's
cyclomatic ≤ 10 cap.

> Drafted by `architect` (auto mode) on 2026-04-26 to back
> ADR-016. Status: **Proposed**.

## Why this is a real decision

The standards (`docs/standards.md` Quality Gates) require
*"linters and formatters MUST pass with zero warnings on changed
files"* — but neither tool is configured today. A baseline must
be picked. The codebase already has Ruff invoked in CI
(`.github/workflows/test.yml:26-27`) and a `.ruff_cache/`
directory present, so "rip and replace" is not the question; the
question is: **stay on Ruff for both lint and format, or
pair it with Black, or split lint and format across separate
tools.**

## Candidates

| # | Tool / combination | Lint | Format | Speed | Config single source | Notes |
|---|--------------------|------|--------|-------|----------------------|-------|
| A | **Ruff (lint + format)** | yes | yes | very fast (Rust core) | `pyproject.toml` `[tool.ruff]` | already in CI; `ruff format` since 0.1.x |
| B | Ruff (lint) + Black (format) | yes | yes | fast lint, fast format | two `[tool.*]` sections | adds one dev-dep; two CI invocations |
| C | Flake8 + Black + isort + mccabe | yes | yes | slowest (Python loops) | multiple files (`.flake8`, `setup.cfg`, `pyproject.toml`) | classic stack; most fragmented |
| D | Pylint (+ Black optional) | yes (very strict) | optional | slow | `.pylintrc` or `pyproject.toml` | known false-positive rate; opinionated |

## Per-candidate detail

### A. Ruff (lint + format)

- **Strengths**:
  - One tool covers Pyflakes, pycodestyle, isort, pyupgrade,
    bugbear, mccabe, simplify, pytest-style, and more — selected
    via `select = […]`.
  - `ruff format` is a Black-compatible formatter with stable
    output across versions.
  - `mccabe` rule supports `max-complexity = 10`, directly
    enforcing Principle III's cyclomatic cap.
  - Single config block in `pyproject.toml`.
  - Already running in CI — zero migration cost.
  - Rust binary; fast on large repos.
- **Limitations**:
  - Newer than Black; format output is now stable (since 0.4.x)
    but a future Ruff bump can still change rule semantics. Pin
    a minor version in `pyproject.toml` to be safe.
  - Not every Pylint check has a Ruff equivalent; some niche
    bug-finding rules (e.g. duplicate-code, similarity reports)
    are absent.
- **Typical cost signal:** free (MIT)
- **Version current at research time:** Ruff 0.15.x line is the
  one cached locally (`.ruff_cache/0.15.12/`); 0.x is still the
  major series at 2026-04-26. `(unverified — confirm latest at
  PR time)` (TDEBT-025).
- **Licence:** MIT (Astral; published under
  <https://github.com/astral-sh/ruff>).
- **Sources:**
  - <https://docs.astral.sh/ruff/> — fetched 2026-04-26 *(via
    Astral's documented behaviour; static reading only — actual
    fetch deferred to confirm)* `(unverified — confirm)`
  - `.ruff_cache/0.15.12/` (local evidence of current version).

### B. Ruff (lint) + Black (format)

- **Strengths**:
  - Black is the de-facto Python formatter and has the largest
    install base — onboarding new contributors is friction-free.
  - Conservative, opinionated output that has been stable for
    years.
- **Limitations**:
  - Two tools to invoke in CI.
  - Two configs (`[tool.ruff]` + `[tool.black]`) to keep aligned
    on `line-length`.
  - Marginal speed loss compared to A.
- **Typical cost signal:** free (MIT)
- **Version current at research time:** Black 24.x major series
  is current `(unverified — confirm)`.
- **Licence:** MIT.
- **Sources:**
  - <https://black.readthedocs.io/> *(unverified — confirm at
    PR time)*
  - <https://docs.astral.sh/ruff/formatter/> for compatibility
    notes (Ruff format is Black-compatible).

### C. Flake8 + Black + isort + mccabe

- **Strengths**:
  - Granular, well-known stack; most CI examples online are
    written for it.
  - Each tool can be swapped independently.
- **Limitations**:
  - Four tools. Each runs in its own subprocess; CI cost is
    additive.
  - Configs spread across `.flake8`, `pyproject.toml`,
    sometimes `setup.cfg`. Drift is a constant risk.
  - Flake8 is slower than Ruff by 1–2 orders of magnitude.
  - mccabe-via-Flake8 needs a separate plugin install.
- **Typical cost signal:** free (MIT / BSD).
- **Version current at research time:** Flake8 7.x; isort 5.x.
  `(unverified — confirm)`.
- **Sources:**
  - <https://flake8.pycqa.org/> *(unverified)*
  - <https://pycqa.github.io/isort/> *(unverified)*

### D. Pylint (+ optional Black)

- **Strengths**:
  - Very thorough; finds duplicate code, bad pattern usage, and
    naming-convention issues that Ruff doesn't currently check.
- **Limitations**:
  - Slow (Python implementation, full type-aware analysis).
  - Famously noisy by default; baseline cleanup is a project
    in itself before "zero warnings" is achievable.
  - Requires `.pylintrc` or `[tool.pylint.*]`; harder to
    document the active rule set.
- **Typical cost signal:** free.
- **Version current at research time:** Pylint 3.x.
  `(unverified — confirm)`.
- **Sources:**
  - <https://pylint.readthedocs.io/> *(unverified)*

## Applicability to KISS's constraints

| Constraint (from `docs/architecture/intake.md`) | A. Ruff | B. Ruff+Black | C. F+B+iso+mc | D. Pylint |
|---|---|---|---|---|
| Lint zero warnings (Quality Gate) | yes — single config | yes | yes | yes (after baseline) |
| Cyclomatic ≤ 10 (Principle III) | yes (`max-complexity`) | yes | yes (mccabe plugin) | yes |
| Format-on-save deterministic | yes | yes | yes | (no formatter) |
| Cross-platform (macOS, Linux, Windows) | yes (Rust binary) | yes | yes | yes |
| Already in repo / CI | yes | (lint yes, format no) | no | no |
| Minimum dev-deps | best (1 tool) | 2 | 4 | 1–2 |
| Speed on this codebase (105 files / 37k LOC) | best | very good | slowest | slow |

## Recommendation (for the human decider)

**Candidate A (Ruff lint + format) is the recommendation.** It
satisfies every architectural constraint, is already in CI, adds
no new dev-deps, and matches the "minimum public surface"
philosophy (one tool, one config block).

The recommendation is captured in **ADR-016**. The decider field
on that ADR is **TBD — confirm**; no decision is locked here.

## Open questions

- TDEBT-025: confirm latest stable Ruff version at PR time and
  pin it in `pyproject.toml` (e.g. `ruff>=0.13,<0.16`).
- TDEBT-026: decide `line-length` (88 default vs. 100 vs.
  current de-facto). Should be measured against the existing
  codebase before pinning, so the first format-only PR isn't
  catastrophic.
- TDEBT-027: enumerate per-file-ignores for the legacy modules
  (`extensions.py`, `presets.py`, `integrations/base.py`) so the
  first lint pass passes; remove the per-file-ignores as
  ADR-013 / ADR-014 land their PRs.
