# ADR-016: Adopt `[tool.ruff]` configuration for lint + format in `pyproject.toml`

**Date:** 2026-04-26
**Status:** Proposed
**Decider:** (decider: TBD — confirm)

## Context

`docs/standards.md` Quality Gates require: *"linters and
formatters MUST pass with zero warnings on changed files."*

The current state (`docs/analysis/codebase-scan.md` §6):

- Ruff is invoked in CI: `uvx ruff check src/`
  (`.github/workflows/test.yml:26-27`).
- A `.ruff_cache/` directory exists locally
  (`.ruff_cache/0.15.12/`).
- **No `[tool.ruff]` section** is present in `pyproject.toml`,
  so Ruff runs with its defaults. The default rule set is a
  modest subset; many style and bug-finding rules are dormant.
- No formatter is wired explicitly. Ruff has had a `format`
  subcommand since 0.1.x, but no PR enforces formatted output.

Without an explicit configuration:

- The "zero warnings" gate is pinned to whatever Ruff's defaults
  happen to be at the running version. A Ruff upgrade silently
  adds or removes rules.
- New contributors do not have a single source of truth for "what
  this project considers a lint warning".
- Format-on-save vs. format-in-CI can disagree, producing PR-time
  surprises.

This is a **research-then-decide** ADR — a candidate research
note exists at `docs/research/python-lint-format-toolchain.md`.

## Decision

KISS pins its Python lint and format toolchain to **Ruff** (lint
*and* format), configured explicitly in `pyproject.toml`:

```toml
[tool.ruff]
target-version = "py311"
line-length = 100
src = ["src", "tests", "scripts"]

[tool.ruff.lint]
select = [
  "E", "F", "W",       # pyflakes + pycodestyle
  "I",                 # isort
  "B",                 # bugbear (likely-bug patterns)
  "C90",               # mccabe complexity
  "UP",                # pyupgrade (3.11+ idioms)
  "SIM",               # simplifications
  "RET",               # return-style
  "RUF",               # Ruff-specific rules
  "PT",                # pytest style
]
ignore = []  # explicit exceptions per file go in per-file-ignores

[tool.ruff.lint.mccabe]
max-complexity = 10  # Principle III: cyclomatic ≤ 10

[tool.ruff.format]
quote-style = "double"
indent-style = "space"
line-ending = "auto"  # cross-platform safe
```

The exact ruleset above is a **recommendation**; the human
decider tunes the `select` list to taste. The non-negotiable
parts (per the standards) are:

1. **`line-length`** is set explicitly (default 88 → bumped to
   100 to match the codebase's current de-facto width;
   `(unverified — confirm)` measure).
2. **`max-complexity = 10`** is mandatory (Principle III).
3. **Ruff format** is wired in CI as
   `uvx ruff format --check src/ tests/ scripts/`.
4. **Ruff lint** is wired in CI as
   `uvx ruff check src/ tests/ scripts/` (today only `src/`).

This ADR ratifies the **decision to add the configuration**, not
the configuration text — the configuration ships in a follow-up
PR (test-first per Principle II: a test verifies the
configuration loads and the project lints clean).

## Consequences

- (+) "Lint zero warnings" becomes a checkable contract — the
  rule set is explicit in version control.
- (+) Format-on-save becomes deterministic; new contributors run
  `uvx ruff format` and get the same output as CI.
- (+) `max-complexity = 10` makes Principle III machine-checked
  for cyclomatic complexity. Function-LOC and nesting limits
  remain reviewer-checked unless extra rules are added.
- (+) Replaces three potential tools (Flake8 + Black + isort)
  with one — fewer dev-deps, faster CI.
- (−) Adding rules will surface existing violations in the
  codebase. Each must be either fixed (preferred) or waived in
  per-file-ignores; waivers must be tracked as TDEBT entries.
- (−) Ruff format is opinionated and will rewrite a lot of files
  on first apply. Mitigated by landing in a single
  format-only PR with a `# noqa` blame-isolation note.

## Alternatives considered

- **Black + isort + Flake8 + mccabe** — rejected; four tools where
  one suffices, and the team has not pinned Black or Flake8 in
  `pyproject.toml` either.
- **Pylint** — rejected; slower, more noisy defaults, and the
  codebase already uses `.ruff_cache/`.
- **Ruff lint only (no format)** — rejected; the standards say
  *formatters MUST pass*, so the formatter must be defined.
- **Keep Ruff defaults** — rejected; explicit beats implicit
  (standards' lint-zero-warnings clause needs an explicit baseline).

See `docs/research/python-lint-format-toolchain.md` for the
candidate-comparison detail and source citations.

## Source evidence

- `docs/standards.md` Quality Gates → "Lint / format"
- `.github/workflows/test.yml:26-27` (Ruff invocation)
- `pyproject.toml:1-101` (no `[tool.ruff]` section today)
- `docs/analysis/codebase-scan.md` §6
