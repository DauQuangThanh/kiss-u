# ADR-002: Use Hatchling + a custom build hook to bundle assets into `core_pack/`

**Date:** 2026-04-26
**Status:** Proposed
**Decider:** (decider: TBD — confirm)

## Context

KISS ships substantial non-Python content: 49 agent-skill
folders, 14 custom-agent prompts, 3 presets, 3 extensions, 1
bundled workflow, and an integrations catalog. These trees live
at the repo root (`agent-skills/`, `subagents/`, `presets/`,
`extensions/`, `workflows/`, `integrations/catalog.json`) so
contributors can edit them as plain files (`CLAUDE.md` "Source of
truth for assets").

A wheel must include all of those plus a per-tree
`sha256sums.txt` for integrity verification. Standard MANIFEST.in
+ `package_data` would require duplicating the tree under
`src/kiss_cli/` or adding many include patterns. The current
solution is a custom Hatchling build hook
(`scripts/hatch_build_hooks.py`) that stages assets to
`build/core_pack/` at build time, runs
`scripts/generate-checksums.py`, and lets `force-include` map
that staging into `kiss_cli/core_pack/` inside the wheel
(`pyproject.toml:25-42`).

## Decision

KISS uses **Hatchling** as the build backend, with a custom
`CustomBuildHook` (`scripts/hatch_build_hooks.py:104`) that:

1. Wipes `build/core_pack/`.
2. Mirrors the asset trees per `ASSET_MAP`
   (`hatch_build_hooks.py:32-48`), excluding `__pycache__/`,
   `.pytest_cache/`, `.DS_Store`, `*.pyc`, `*.pyo`, and any path
   part starting with `_` (so `agent-skills/_template/` does not
   ship).
3. Generates `build/core_pack/sha256sums.txt` via
   `scripts/generate-checksums.py`.

The wheel's `[tool.hatch.build.targets.wheel.force-include]`
maps `build/core_pack` → `kiss_cli/core_pack`
(`pyproject.toml:41-42`). The sdist re-includes the repo-root
trees so a wheel built from sdist reproduces the same bundle.

`build/` is gitignored (`.gitignore:6-11`); contributors must
edit the repo-root trees, never `build/core_pack/`.

## Consequences

- (+) Single source of truth for assets at the repo root —
  reviewers see the actual file they're shipping.
- (+) Hash-based integrity baked at build time, not run time.
- (+) Works for both wheel and sdist via `force-include` and
  sdist `include` settings.
- (−) New asset directories require updating `ASSET_MAP` in the
  hook (one place; `CLAUDE.md` "Guidelines" notes the build hook
  picks up new presets / extensions / workflows automatically as
  long as they live in their existing top-level directories).
- (−) The hook is a custom plugin; future Hatchling versions may
  change the interface.
- (−) Asset corruption between build and install is detected by
  `_integrity.verify_asset_integrity()` (`_integrity.py:24-79`)
  but its production call site is missing today — see TDEBT-002.

## Alternatives considered

- **MANIFEST.in + `package_data`** with assets duplicated under
  `src/kiss_cli/` — rejected because contributors would have to
  edit two locations.
- **Setuptools + `include_package_data`** — rejected; the build
  semantics are less explicit and cross-platform packaging is
  flakier.
- **Poetry + custom plugins** — rejected; the project standardised
  on `uv` (`uv.lock`, `astral-sh/setup-uv` in CI).

## Source evidence

- `pyproject.toml:25-42`
- `scripts/hatch_build_hooks.py:32-48,104-144`
- `scripts/generate-checksums.py:31-68`
- `CLAUDE.md` "Source of truth for assets"
