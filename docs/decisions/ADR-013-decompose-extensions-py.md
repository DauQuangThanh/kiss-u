# ADR-013: Decompose `extensions.py` (2,493 LOC) into the `extensions/` package

**Date:** 2026-04-26
**Status:** Proposed
**Decider:** (decider: TBD — confirm)

## Context

`src/kiss_cli/extensions.py` is 2,493 lines and contains seven
concerns mixed in a single file
(`docs/analysis/codebase-scan.md` §2 hot files;
`docs/architecture/extracted.md` §3, §8):

- Manifest loading + validation (`ExtensionManifest`,
  `ExtensionManifest._validate`, `_load_yaml`).
- Catalog lookup (`ExtensionCatalog`).
- Installed-extension bookkeeping (`ExtensionRegistry`).
- Per-extension config (`ConfigManager`).
- Hook execution (`HookExecutor`) — the only `subprocess`-calling
  component.
- Frontmatter parse / render (the local `CommandRegistrar` —
  name-collides with `kiss_cli.agents.CommandRegistrar`,
  TDEBT-020).
- The orchestrator (`ExtensionManager`, with 14+ methods spanning
  ~793 LOC).

Plus module-level helpers (`_load_core_command_names`,
`normalize_priority`, `version_satisfies`), a dataclass
(`CatalogEntry`), and three exception types.

This violates **Principle III** at every level the standards
measure: the module is ~60× the soft module-size signal implied
by "≤ 40 executable LOC per function"; multiple methods inside
`ExtensionManager` are too large to read on one screen; the I/O /
pure-logic boundary is implicit.

The standards also forbid undertaking new abstractions without a
concrete justification (Principle I). The justification here is
the concrete violation of Principle III in this one module.

## Decision

Decompose `src/kiss_cli/extensions.py` into a package
`src/kiss_cli/extensions/` with the layout below. **No public
class names change.** A facade `extensions/__init__.py` re-exports
the names so existing callers (`cli/extension.py`, `cli/init.py`,
`presets/manager.py`) keep working unchanged.

| Module | Public surface (preserve names) | Pure / I/O |
|---|---|---|
| `extensions/__init__.py` | re-exports `ExtensionManifest`, `ExtensionRegistry`, `ExtensionManager`, `ExtensionCatalog`, `ConfigManager`, `HookExecutor`, `CommandRegistrar`, `ExtensionError`, `ValidationError`, `CompatibilityError`, `CatalogEntry`, `version_satisfies`, `normalize_priority` | facade |
| `extensions/errors.py` | `ExtensionError`, `ValidationError`, `CompatibilityError` | pure |
| `extensions/version.py` | `version_satisfies`, `normalize_priority` | pure |
| `extensions/core_commands.py` | `_load_core_command_names` | I/O at edge |
| `extensions/manifest.py` | `ExtensionManifest`, `CatalogEntry` | I/O at edge (`_load_yaml`); `_validate` pure |
| `extensions/registry.py` | `ExtensionRegistry` | I/O at edge |
| `extensions/catalog.py` | `ExtensionCatalog` | I/O at edge |
| `extensions/config.py` | `ConfigManager` | I/O at edge |
| `extensions/hooks.py` | `HookExecutor` | only module that calls `subprocess` |
| `extensions/frontmatter.py` | (local) `CommandRegistrar` | pure |
| `extensions/manager.py` | `ExtensionManager` | composes I/O |

**Sizing constraints (per Principle III):**

- ≤ 400 LOC per module (target).
- ≤ 40 executable LOC per function.
- Cyclomatic complexity ≤ 10.
- Nesting depth ≤ 3.
- Public surface = exactly the names re-exported from
  `extensions/__init__.py`.

**Test-first cadence (per Principle II):**

The decomposition ships in **multiple PRs**, each one a Red →
Green → Refactor cycle:

1. PR-A: extract `errors.py` and `version.py` (pure modules).
   Tests added first; `extensions.py` re-imports the names.
2. PR-B: extract `manifest.py` + `catalog.py`. Tests added first
   for parse / validation paths.
3. PR-C: extract `registry.py` + `config.py` + `core_commands.py`.
4. PR-D: extract `hooks.py`. New unit tests for subprocess
   isolation, deleting any `subprocess` calls from siblings.
5. PR-E: extract `frontmatter.py`.
6. PR-F: split `ExtensionManager` methods to ≤ 40 LOC each;
   move into `manager.py`; flip `extensions.py` to a stub that
   raises `DeprecationWarning` and re-exports from
   `extensions.__init__`.

Each PR keeps the public class signature unchanged so existing
tests pass; new tests are added per PR for the freshly-extracted
module before its body is moved.

## Consequences

- (+) Brings `extensions.py` into compliance with Principle III.
- (+) Side-effect-typed split (pure / file I/O / subprocess)
  makes Principle IV testable — pure helpers no longer need
  filesystem fakes.
- (+) Each module gets focused tests; current
  `tests/test_extensions.py` can be split mirroring the package.
- (+) The `HookExecutor` subprocess boundary is finally explicit
  and isolatable for security review.
- (−) Six PRs of churn for behaviour-preserving refactor.
  Mitigated by Principle V (refactor-only PRs ship separately
  from behaviour changes; tests do not change except to keep
  compiling).
- (−) Import paths change for code that reaches *into*
  `extensions.py` for private symbols (e.g. `from
  kiss_cli.extensions import _load_core_command_names`). That is
  a Principle-I violation in the caller and is fixed in the same
  PR.
- (−) Resolving the `CommandRegistrar` name collision (TDEBT-020)
  is *not* in scope here — the local class keeps its name but
  moves to `extensions/frontmatter.py`. A separate ADR can
  rename it later.

## Alternatives considered

- **Leave `extensions.py` alone, document the violation as
  technical debt** — rejected; the standards mark Principle III
  as enforceable at PR review, so any new method added to
  `ExtensionManager` would already be over the size limit.
- **Single big PR** — rejected; reviewers cannot effectively
  audit a 2,500-line refactor in one pass.
- **Decompose by class only (one module per class)** — rejected;
  doesn't isolate I/O from pure logic, so Principle IV stays
  implicit.
- **Decompose by feature (install / remove / list)** — rejected;
  cuts across class boundaries and forces shared mutable state.

## Source evidence

- `src/kiss_cli/extensions.py:99,129,134,139,144,164-165,174,391,628,1421,1439,1524,1865,2063`
  (current class / function entry lines)
- `docs/analysis/codebase-scan.md` §2 (LOC count)
- `docs/architecture/extracted.md` §3, §8
- `docs/standards.md` Principle III, IV, V
