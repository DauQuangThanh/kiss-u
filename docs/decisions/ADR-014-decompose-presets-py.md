# ADR-014: Decompose `presets.py` (2,098 LOC) into the `presets/` package

**Date:** 2026-04-26
**Status:** Proposed
**Decider:** (decider: TBD — confirm)

## Context

`src/kiss_cli/presets.py` is 2,098 lines and parallels
`extensions.py` in shape (`docs/analysis/codebase-scan.md` §2;
`docs/architecture/extracted.md` §3):

- Manifest loading + validation (`PresetManifest`, `_load_yaml`,
  `_validate`).
- Catalog lookup (`PresetCatalog`).
- Installed-preset bookkeeping (`PresetRegistry`).
- Resolution / dependency math (`PresetResolver`).
- Per-preset skill register / unregister + restore-index logic
  (`_register_skills`, `_unregister_skills`, `_replay_skill_override`,
  `_build_extension_skill_restore_index`).
- Per-preset command register / unregister + replay
  (`_register_commands`, `_unregister_commands`,
  `_replay_wraps_for_command`, `_skill_title_from_command`).
- The orchestrator (`PresetManager`, with ~14+ methods).

Plus `_substitute_core_template` (pure helper), three exception
types, and the dataclass `PresetCatalogEntry`.

The same Principle III / Principle IV gap that motivates ADR-013
applies here. Treating extensions and presets as parallel
problems with parallel solutions reduces reviewer load — once a
contributor learns the shape of `extensions/`, `presets/` is
familiar.

## Decision

Decompose `src/kiss_cli/presets.py` into a package
`src/kiss_cli/presets/`. Public class names are preserved; a
facade `presets/__init__.py` re-exports them.

| Module | Public surface (preserve names) | Pure / I/O |
|---|---|---|
| `presets/__init__.py` | re-exports `PresetManifest`, `PresetRegistry`, `PresetManager`, `PresetCatalog`, `PresetResolver`, `PresetError`, `PresetValidationError`, `PresetCompatibilityError`, `PresetCatalogEntry` | facade |
| `presets/errors.py` | three exception types | pure |
| `presets/templates.py` | `_substitute_core_template` | pure |
| `presets/resolver.py` | `PresetResolver` | pure |
| `presets/manifest.py` | `PresetManifest`, `PresetCatalogEntry` | I/O at edge |
| `presets/registry.py` | `PresetRegistry` | I/O at edge |
| `presets/catalog.py` | `PresetCatalog` | I/O at edge |
| `presets/skills.py` | (private) `_register_skills`, `_unregister_skills`, `_replay_skill_override`, `_build_extension_skill_restore_index` | I/O at edge |
| `presets/commands.py` | (private) `_register_commands`, `_unregister_commands`, `_replay_wraps_for_command`, `_skill_title_from_command` | I/O at edge |
| `presets/manager.py` | `PresetManager` | composes I/O |

Sizing constraints identical to ADR-013 (≤ 400 LOC per module,
≤ 40 LOC per function, cyclomatic ≤ 10, nesting ≤ 3, public
surface = `__init__.py` re-exports).

Test-first cadence (Principle II) ships as multiple PRs in the
same shape as ADR-013:

1. PR-A: `errors.py`, `templates.py`, `resolver.py` (pure).
2. PR-B: `manifest.py`, `catalog.py`.
3. PR-C: `registry.py`.
4. PR-D: `skills.py`, `commands.py`.
5. PR-E: split `PresetManager` methods to ≤ 40 LOC; move into
   `manager.py`; flip `presets.py` to deprecation stub.

## Consequences

- (+) Brings `presets.py` into compliance with Principle III.
- (+) Pure resolver (`PresetResolver`) is finally testable
  without any filesystem setup.
- (+) Skill / command registration helpers, currently buried as
  private methods on `PresetManager`, become independently
  testable modules.
- (+) Symmetric layout with the `extensions/` package (ADR-013)
  reduces cognitive load for contributors.
- (−) Five PRs of churn (same risk profile as ADR-013).
- (−) Cross-package dependency: `PresetManager` calls into
  `extensions.ExtensionManager` to compute the skill-restore
  index. The dependency stays through the facade
  (`from kiss_cli.extensions import …`); no circular import is
  introduced — verified by the existing dependency map showing
  `presets.py` → `extensions.py` is a one-way edge today
  (`docs/analysis/dependencies.md` §2 row 13).

## Alternatives considered

- **Merge presets and extensions into a single `packs/` package**
  — rejected; presets and extensions have different lifecycle
  semantics (a preset *composes* extensions plus extra
  templates) and CLI verbs. Merging would force a larger public
  surface for marginal sharing.
- **Single big PR** — rejected; review burden.
- **Leave as-is** — rejected; same Principle III violation.
- **Use `attrs` / `pydantic` for manifests** — rejected
  (Principle I, YAGNI); the existing dataclass + dict shape is
  enough.

## Source evidence

- `src/kiss_cli/presets.py:33,86-87,96,101,106,114,271,502,1483,1797`
  (current class / function entry lines)
- `docs/analysis/codebase-scan.md` §2 (LOC count)
- `docs/architecture/extracted.md` §3
- `docs/analysis/dependencies.md` §2
- `docs/standards.md` Principle III, IV, V
