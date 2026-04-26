# Development Notes

kiss is a toolkit for spec-driven development. At its core it is a coordinated
set of prompts, templates, scripts, and CLI/integration assets that define and
deliver a spec-driven workflow for AI coding agents. This document is a
starting point for people modifying kiss itself, with a compact orientation to
the key project documents and repository organization.

**Essential project documents:**

| Document                                                   | Role                                                                                    |
| ---------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| [README.md](README.md)                                     | Primary user-facing overview of kiss and its workflow.                                  |
| [CLAUDE.md](CLAUDE.md)                                     | Source of truth for kiss requirements and design decisions.                             |
| [DEVELOPMENT.md](DEVELOPMENT.md)                           | This document.                                                                          |
| [CONTRIBUTING.md](CONTRIBUTING.md)                         | Contribution process, review expectations, testing, and required development practices.|
| [CHANGELOG.md](CHANGELOG.md)                               | Release history (auto-populated by the release-trigger workflow).                       |
| [RELEASE-PROCESS.md](.github/workflows/RELEASE-PROCESS.md) | Release workflow, versioning rules, and changelog generation process.                   |
| [docs/index.md](docs/index.md)                             | Entry point to the `docs/` documentation set.                                           |

**Main repository components:**

| Directory                 | Role                                                                                       |
| ------------------------- | ------------------------------------------------------------------------------------------ |
| `src/kiss_cli/`           | Python source for the `kiss` CLI, including agent-specific integrations.                   |
| `build/core_pack/`        | **Build staging area** (gitignored). Populated by `scripts/hatch_build_hooks.py` during `uv build`, then mapped into the wheel as `kiss_cli/core_pack/` via `force-include`.|
| `agent-skills/`           | Per-skill bundles — each `agent-skills/<kiss-name>/` ships a command prompt plus the scripts and templates it depends on. `agent-skills/_template/` is developer-only scaffolding (underscore prefix → excluded from the wheel). |
| `subagents/`          | Role-based AI agent prompts (architect, tester, devops, …) deployed to each integration's subagents directory on `kiss init`. Each delegates to skills under `agent-skills/`. |
| `scripts/`                | Build utilities (`hatch_build_hooks.py`, `generate-checksums.py`).                         |
| `extensions/`             | Bundled extensions, developer guides, and the scaffold template.                           |
| `presets/`                | Bundled presets (lean, scaffold, self-test) and preset-system docs.                        |
| `workflows/`              | Workflow orchestration definitions and docs; `workflows/kiss/` is the default workflow.    |
| `integrations/`           | Integration catalog metadata (Python code lives under `src/kiss_cli/integrations/`).       |
| `docs/`                   | User-facing documentation, published via DocFX.                                            |
| `tests/`                  | Pytest test suite.                                                                         |

## How assets ship in the wheel

On every `uv build`, `scripts/hatch_build_hooks.py` mirrors the top-level
asset trees into `build/core_pack/`, then regenerates
`core_pack/sha256sums.txt`. Hatchling's `force-include` mapping in
`pyproject.toml` (`"build/core_pack" = "kiss_cli/core_pack"`) copies that
staged tree into the wheel under `kiss_cli/core_pack/`, so the published
wheel ships every preset, extension, workflow, agent-skill, and support
script — and `kiss init` and `kiss upgrade` run fully offline after install.

Add a new preset / extension / workflow by dropping its directory into the
matching top-level folder; no `pyproject.toml` edit is required.

## Development checklist

- `uv sync` — install development dependencies.
- `uv run pytest tests/ -q` — run the test suite (requires Python ≥ 3.11).
- `uv build` — produce a wheel and sdist in `dist/` via the custom build hook.
