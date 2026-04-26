# Architecture Intake

**Date:** 2026-04-26
**Feature / scope:** KISS CLI installer (whole-system architecture re-design)

> Drafted by `architect` (auto mode) on 2026-04-26 from
> `docs/standards.md` v1.0.0, `docs/architecture/extracted.md`, the
> `docs/analysis/` outputs, and `CLAUDE.md`. Every concrete value is
> sourced; unverifiable items are flagged `(unverified — confirm)`
> and logged as `TDEBT-` entries in `tech-debts.md`.

## 0. Mode & decider

- Authoring mode: `auto` (the user instructed "in auto mode" in the
  prompt). The agent did not run the interactive questionnaire;
  instead, defaults were inferred from the standards, the
  technical-analyst's findings, and `CLAUDE.md`.
- Decider for any locked architectural choice: **TBD — confirm**.
  This intake captures the *current* observable shape plus
  *recommended* re-design moves; it does not commit the project to
  anything. ADRs in `docs/decisions/` carry the same TBD decider
  and remain `Proposed` until a human accepts.

## 1. Quality attributes — ranked (1 highest → 5 lowest)

The ranking is grounded in the standards (Principles I–V) and the
operational reality that KISS is a one-shot bootstrap CLI. Every
rank is a recommendation; the human owner can reorder.

1. **Cross-platform parity** — the project explicitly mandates
   Bash + PowerShell parity (`docs/standards.md` Quality Gates;
   `CLAUDE.md` "Cross-platform shells"). CI runs the test matrix
   `{ubuntu, windows} × {3.11, 3.12, 3.13}`
   (`.github/workflows/test.yml:30-55`). This is the floor.
2. **Install-time correctness (idempotence + integrity)** — the
   install must produce a verifiable, hash-tracked tree the user
   can later upgrade or uninstall safely
   (`integrations/manifest.py:50-265`, `_integrity.py:24-79`,
   `scripts/generate-checksums.py:31-68`). Failures here corrupt
   user projects.
3. **Offline-first operation** — defended by `tests/test_offline.py`
   and the `_locate_bundled_catalog_file()` indirection
   (`_bundled_catalogs.py:28-45`). The wheel must be self-contained
   so `kiss init` and `kiss upgrade` never reach the network.
4. **Simplicity of generated output** — the standards principle I
   (KISS / YAGNI) is project-wide and applies to the *output* tree
   the installer writes into the user's project as much as to KISS
   itself. Generated `.kiss/` content stays minimal and explicit.
5. **Maintainability of the installer codebase** — Principles
   I–V again, but applied to `src/kiss_cli/`. Today this is the
   weakest attribute: `extensions.py` (2,493 LOC) and `presets.py`
   (2,098 LOC) violate Principle III ("Small, Focused Units") at
   module scale (`docs/analysis/codebase-scan.md` §2 hot files).

Lower-priority but still tracked:

6. **Performance** — the CLI is short-lived; throughput is not a
   driver. Step UI is `Rich`-rendered and human-facing, not
   contended.
7. **Security of the installed tree** — addressed via SHA-256
   manifests (CADR-004) and by *not* executing arbitrary code at
   install time. Treated as a constraint, not a primary attribute.

## 2. Hard constraints

Harvested from the standards, `CLAUDE.md`, and the codebase scan.

- **Runtime is offline after install.** `uv tool install` (or wheel
  install) is the only network step; everything KISS does at
  runtime must come from the wheel bundle (`CLAUDE.md` "Offline
  operation"; `_bundled_catalogs.py:1-12,28-45`;
  `tests/test_offline.py`).
- **Both shells must ship.** Every skill carries a `scripts/bash/`
  *and* a `scripts/powershell/` (`agent-skills/_template/`,
  `skill_assets.py:79-127`); parity is a Quality Gate
  (`docs/standards.md` Quality Gates → "Parity").
- **Test-first is non-negotiable.** Principle II is marked
  NON-NEGOTIABLE in the standards; production code without a test
  in the same diff must be rejected at review.
- **Module / function size limits are mechanical.** Principle III
  caps functions at ≤ 40 LOC executable, cyclomatic complexity ≤
  10, nesting depth ≤ 3, plus minimum public surface.
- **Cross-platform support: macOS, Linux, Windows.** All three are
  team-targeted (`CLAUDE.md` "Cross-platform shells"). CI covers
  Ubuntu and Windows; macOS support is asserted in `CLAUDE.md` but
  not in CI (logged as TDEBT-014, see `tech-debts.md`).
- **Python `>=3.11`.** `pyproject.toml:5`. CI matrix covers 3.11,
  3.12, 3.13.
- **Source-of-truth for assets is at the repo root.** The five
  asset trees (`agent-skills/`, `presets/`, `extensions/`,
  `workflows/`, `integrations/catalog.json`) are authoritative;
  `build/core_pack/` is gitignored staging
  (`CLAUDE.md` "Source of truth for assets";
  `scripts/hatch_build_hooks.py:32-48`).
- **Static integration registry.** Built-ins are listed inline in
  `_register_builtins()` (`integrations/__init__.py:40-81`); no
  plugin discovery, by design (CADR-009).
- **No direct push to remote in CI.** Releases are tag-triggered,
  package and attach artefacts only (CADR-008,
  `.github/workflows/release.yml:1-141`). Direct pushes to `main`
  are forbidden by the standards' Development Workflow.
- **Lint-zero-warnings policy.** Quality Gates require zero
  warnings on changed files; today no `[tool.ruff]` block is
  configured in `pyproject.toml`, so the lint surface is implicit
  (`docs/analysis/codebase-scan.md` §6). Recommended ADR:
  `ADR-016` (adopt explicit `[tool.ruff]` + format configuration).
- **Coverage gate ≥ 80% on changed files.** No coverage threshold
  is currently configured in `pyproject.toml`
  (`docs/analysis/codebase-scan.md` §5). Recommended follow-up
  outside this re-design: wire pytest-cov `--cov-fail-under` once
  ADR-016 lands. (logged as TDEBT-015)
- **Output language: English.** `.kiss/context.yml` `language.output`
  default applies to every artefact this re-design produces.

## 3. Team context

- **Team size band:** single-developer / very small team
  (inferred from the AI-driven SDD framing in `CLAUDE.md` —
  *"the single human user at the keyboard"*). `(unverified —
  confirm)` (logged as TDEBT-016).
- **Existing skill set:** Python 3.11+, Typer/Click, Rich,
  pytest, Bash, PowerShell, YAML, Markdown, GitHub Actions, uv.
  All confirmed by the codebase scan.
- **Hiring plans:** unknown; not a relevant constraint for an
  AI-authoring CLI.

## 4. Operational envelope

KISS is a CLI installer, not a server.

- **Concurrent users / total users:** N/A — CLI invocation is
  per-user, per-machine, single-process.
- **Peak QPS:** N/A.
- **Throughput target:** `kiss init` should complete in seconds on
  a developer laptop; no formal SLO. (logged as TDEBT-017 —
  decide if a wall-clock budget is worth pinning)
- **Data volume:** the only persistent output is the user project
  tree under `<project>/.kiss/` plus per-AI directories. Sizes are
  bounded by the bundled assets (≈ 49 skills, ≈ 14 role-agents).
- **Availability target:** N/A (no service runtime).
- **RTO / RPO:** N/A.
- **Failure-mode characteristics:**
  - On `kiss init` failure with `--here=False`,
    `shutil.rmtree(project_path)` cleans the freshly-created dir
    (`cli/init.py:506-507`).
  - On `kiss integration install` failure, rollback runs via
    `integration.teardown(..., force=True)`
    (`cli/integration.py:248-256`).
  - Manifest hashing protects against silent edits during
    upgrade/uninstall.

## 5. Integration surface

- **Identity provider:** N/A.
- **Payment / billing:** N/A.
- **ERP / CRM / Email / SMS / Data warehouse:** N/A.
- **AI providers — supported set (per `docs/AI-urls.md` and
  ADR-018, narrowed 2026-04-26):** **seven** — Claude Code,
  GitHub Copilot, Cursor Agent, OpenCode, Windsurf, Gemini
  CLI, Codex.
- **AI providers — currently in code (13):** the seven above
  plus Antigravity (`agy`), Auggie, Kilocode, Kiro CLI,
  Tabnine, Generic — `integrations/__init__.py:50-81`. The
  six unsupported entries are pending removal in a future
  source-code pass; spec/code divergence is tracked as
  TDEBT-028 / RDEBT-024.
- **Distribution / hosting:**
  - **GitHub** — code, CI, releases (tag-triggered) at
    `https://github.com/DauQuangThanh/kiss-u`
    (`pyproject.toml:19-20`).
  - **PyPI** — `(unverified — confirm)`. Only GitHub Releases
    artefacts are wired today (ANALYSISDEBT-004 / TDEBT-018 here).
- **Build dependencies:** `hatchling` build backend; custom hook
  at `scripts/hatch_build_hooks.py`.
- **Shell-out integrations:** `git init`, `git add`, `git commit`
  (`installer.py:128-149`); the AI CLIs themselves via
  `IntegrationBase.dispatch_command`
  (`integrations/base.py:147-225`).
- **No HTTP / database / queue surface.** The installer never
  opens a network socket once installed; this is enforced by
  `tests/test_offline.py`.

## 6. Deployment preferences

- **Managed services vs. self-hosted:** N/A — KISS is distributed
  software, not a service.
- **Preferred distribution:** wheel + sdist via GitHub Releases
  (`.github/workflows/release.yml:128-138`). PyPI publishing is
  TBD (TDEBT-018).
- **Install command (current):** `uv tool install kiss-u` (or
  whichever wheel name is finalised when PyPI is wired) —
  `(unverified — confirm)` (TDEBT-019).

## 7. Architectural shape — current vs. recommended

### 7.1 Containers (current)

Five runtime contexts identified in `extracted.md` §2:

- C1 · `kiss` CLI process (Typer + Click; Python 3.11+).
- C2 · Hatch build hook (build-time only).
- C3 · `core_pack` static asset bundle inside the wheel.
- C4 · Installed agent skills (per-AI runtime targets, e.g.
  `.claude/skills/`, `.gemini/commands/`).
- C5 · External AI provider CLI/IDE processes (invoked by the user
  *after* `kiss init`; sometimes spawned by KISS via
  `dispatch_command`).
- C6 · GitHub Actions CI runner (build, test, lint, release).

This re-design **keeps** all six containers; the boundaries are
sound.

### 7.2 Components (recommended re-design moves)

Two components inside C1 violate Principle III at module scale and
need decomposition. The recommended packages below preserve the
existing public class names — no renames — so callers
(`cli/extension.py`, `cli/preset.py`) keep working through one
re-export shim during the transition.

#### 7.2.1 Decompose `extensions.py` (2,493 LOC, 4 classes)

Today (`grep -n '^class' extensions.py`):

- `ExtensionManifest` (lines 174–390) — manifest loading +
  validation + accessors.
- `ExtensionRegistry` (lines 391–627) — installed-extension
  bookkeeping.
- `ExtensionManager` (lines 628–1420) — the install / remove /
  list workflow.
- `CommandRegistrar` (lines 1439–1523) — frontmatter parse + render
  helpers (note: this is a *different class* from
  `kiss_cli.agents.CommandRegistrar` — name collision, see
  TDEBT-020).
- `ExtensionCatalog` (lines 1524–1864) — catalog (search, info).
- `ConfigManager` (lines 1865–2062) — config-file management.
- `HookExecutor` (lines 2063–end) — extension hook execution.

Plus module-level helpers: `_load_core_command_names`,
`normalize_priority`, `version_satisfies`, exception types
(`ExtensionError`, `ValidationError`, `CompatibilityError`),
dataclass `CatalogEntry`.

**Recommended package layout** (`src/kiss_cli/extensions/`):

| Module | Public surface (existing names; no renames) | Purpose |
|---|---|---|
| `extensions/__init__.py` | re-exports `ExtensionManifest`, `ExtensionRegistry`, `ExtensionManager`, `ExtensionCatalog`, `ConfigManager`, `HookExecutor`, `CommandRegistrar`, `ExtensionError`, `ValidationError`, `CompatibilityError`, `CatalogEntry`, `normalize_priority`, `version_satisfies` | Backward-compatible facade |
| `extensions/errors.py` | `ExtensionError`, `ValidationError`, `CompatibilityError` | Pure |
| `extensions/version.py` | `version_satisfies`, `normalize_priority` | Pure (Principle IV) |
| `extensions/core_commands.py` | `_load_core_command_names` | Reads bundled core list — I/O at edge |
| `extensions/manifest.py` | `ExtensionManifest`, `CatalogEntry` | YAML parsing + validation. I/O isolated to `_load_yaml`; `_validate` stays pure |
| `extensions/registry.py` | `ExtensionRegistry` | Reads/writes `.kiss/extensions/registry.json`; I/O via injected paths |
| `extensions/catalog.py` | `ExtensionCatalog` | Search / info / catalog management |
| `extensions/config.py` | `ConfigManager` | Per-extension config files |
| `extensions/hooks.py` | `HookExecutor` | Subprocess execution; the *only* module that shells out |
| `extensions/frontmatter.py` | (local) `CommandRegistrar` (frontmatter helpers) | Pure parse / render |
| `extensions/manager.py` | `ExtensionManager` | Orchestrator — composes the modules above |

**I/O boundary discipline (Principle IV):**

- All filesystem reads / writes live in `manifest.py`,
  `registry.py`, `catalog.py`, `config.py`, `core_commands.py`.
- `version.py`, `frontmatter.py`, and the `_validate` portions of
  `manifest.py` stay pure — same input, same output, no globals.
- `hooks.py` is the only place that calls `subprocess`.

Sizing target: each module **< 400 LOC**, each public method
**≤ 40 executable LOC**, cyclomatic complexity **≤ 10**. Today's
`ExtensionManager` (≈ 793 LOC, 14+ methods including
`_register_extension_skills`, `install_from_directory`,
`install_from_zip`, `remove`, `list_installed`, `get_extension`,
`check_compatibility`) is the largest single class and will need
sub-method extraction during decomposition; that work is governed
by Principles II (test-first) and V (continuous refactoring).

This decomposition is the subject of **ADR-013** (proposed below).

#### 7.2.2 Decompose `presets.py` (2,098 LOC, 5 classes)

Today (`grep -n '^class' presets.py`):

- `PresetManifest` (114–270) — manifest loading + validation.
- `PresetRegistry` (271–501) — installed-preset bookkeeping.
- `PresetManager` (502–1482) — install / remove workflow plus
  skill / command registration.
- `PresetCatalog` (1483–1796) — catalog management.
- `PresetResolver` (1797–end) — resolves preset dependencies /
  precedence.

Plus module-level: `_substitute_core_template`, dataclass
`PresetCatalogEntry`, exceptions (`PresetError`,
`PresetValidationError`, `PresetCompatibilityError`).

**Recommended package layout** (`src/kiss_cli/presets/`):

| Module | Public surface | Purpose |
|---|---|---|
| `presets/__init__.py` | re-exports `PresetManifest`, `PresetRegistry`, `PresetManager`, `PresetCatalog`, `PresetResolver`, `PresetError`, `PresetValidationError`, `PresetCompatibilityError`, `PresetCatalogEntry` | Backward-compatible facade |
| `presets/errors.py` | the three exception types | Pure |
| `presets/templates.py` | `_substitute_core_template` | Pure (Principle IV) |
| `presets/manifest.py` | `PresetManifest`, `PresetCatalogEntry` | YAML parse + validation; `_validate` pure |
| `presets/registry.py` | `PresetRegistry` | `.kiss/presets/registry.json` I/O |
| `presets/catalog.py` | `PresetCatalog` | Catalog mgmt |
| `presets/resolver.py` | `PresetResolver` | Pure resolution algorithm |
| `presets/skills.py` | (private) `_register_skills`, `_unregister_skills`, `_replay_skill_override`, `_build_extension_skill_restore_index` | Skill-restore index + replay |
| `presets/commands.py` | (private) `_register_commands`, `_unregister_commands`, `_replay_wraps_for_command`, `_skill_title_from_command` | Command registration helpers |
| `presets/manager.py` | `PresetManager` | Orchestrator |

Same Principle-IV discipline as extensions: I/O stays in
`manifest.py`, `registry.py`, `catalog.py`; everything else stays
pure or composes other modules' I/O explicitly.

This decomposition is the subject of **ADR-014** (proposed below).

### 7.3 Other re-design ADRs proposed

- **ADR-015** — Mandate Bash/PowerShell parity at the architecture
  level (today implicit; surface as an architectural invariant
  with parity-tests as Quality Gate).
- **ADR-016** — Adopt `[tool.ruff]` configuration (lint + format)
  in `pyproject.toml`; this lets the lint-zero-warnings Quality
  Gate be enforceable.
- **ADR-017** — Defend the offline-runtime invariant via boundary
  tests (extend `tests/test_offline.py` to cover all CLI
  subcommands, not just `init`).

These are recorded as ADRs `Proposed` only — the agent does
not implement them; the human owner accepts and another agent
implements (per Principle II, with tests first).

## 8. Standards conformance — gap summary

Cross-checked against `docs/standards.md` §Quality Gates:

| Gate | Today | Gap |
|---|---|---|
| Tests pass on macOS / Linux / Windows × Bash / PowerShell | CI covers Ubuntu+Windows; macOS not in matrix `(unverified — confirm)` | Add macOS to matrix or document the waiver — TDEBT-014 |
| ≥ 80% coverage on changed files | Coverage configured but no threshold (`pyproject.toml:94-101`) | Wire `--cov-fail-under=80` after ADR-016 — TDEBT-015 |
| Cyclomatic complexity ≤ 10 / function ≤ 40 LOC / nesting ≤ 3 | `extensions.py`, `presets.py` orders of magnitude over | ADR-013, ADR-014 |
| Lint zero warnings on changed files | Ruff invoked in CI; no `[tool.ruff]` config in `pyproject.toml` | ADR-016 |
| Markdown lint passes | `markdownlint-cli2` wired in `.github/workflows/lint.yml` | None |
| Bash/PowerShell parity per PR | Skills folder structure enforces it (`agent-skills/_template/`); no automated parity test detected | ADR-015 + parity test — TDEBT-021 |
| Public-API changes update tests + docs | Workflow rule | Cultural; not a re-design item |

## 9. Unknowns / open questions

Mirrored as `TDEBT-` entries in `tech-debts.md`. Highlights:

- Decider for every ADR proposed (TDEBT-001 … TDEBT-012 promote
  the candidate ADRs; TDEBT-013 … cover re-design ADRs).
- macOS CI coverage status (TDEBT-014).
- Coverage threshold target (TDEBT-015).
- Team-size confirmation (TDEBT-016).
- Performance budget for `kiss init` (TDEBT-017).
- PyPI publication intent (TDEBT-018).
- Final installable package name on PyPI (TDEBT-019).
- Name collision: two `CommandRegistrar` classes
  (`kiss_cli.agents.CommandRegistrar` vs. the local one inside
  `extensions.py`) — TDEBT-020.
- Automated Bash/PowerShell parity test (TDEBT-021).
