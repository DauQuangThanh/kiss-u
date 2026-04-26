# Contributing to kiss

Thanks for your interest in improving kiss! This guide covers how to get set up,
test your changes, and prepare them for review.

## Quick start

```bash
git clone https://github.com/DauQuangThanh/kiss-u.git
cd kiss
uv sync                               # install runtime + dev deps
uv run pytest tests/ -q               # run the test suite
uv build                              # build the wheel/sdist locally
```

Python ≥ 3.11 is required.

## Repository layout

| Path                 | Role                                                                                         |
| -------------------- | -------------------------------------------------------------------------------------------- |
| `src/kiss_cli/`      | Python source for the `kiss` CLI, including agent-specific integrations.                     |
| `build/core_pack/`   | **Build staging area** (gitignored). Populated by `scripts/hatch_build_hooks.py` during `uv build`, then mapped into the wheel as `kiss_cli/core_pack/` via `force-include`. |
| `agent-skills/`      | Per-skill bundles — each `agent-skills/<kiss-name>/` ships a command prompt plus the scripts and templates it depends on. |
| `scripts/`           | Build utilities (`hatch_build_hooks.py`, `generate-checksums.py`).                           |
| `presets/`           | Presets (lean, scaffold, self-test). Each ships a `preset.yml` plus `commands/` + `templates/`. |
| `extensions/`        | Bundled extensions (e.g. `git/`) plus developer guides and the scaffold template.            |
| `workflows/`         | Workflow orchestration definitions. `workflows/kiss/` is the default workflow bundled with every install. |
| `integrations/`      | Agent integration catalog metadata. Python code for each integration lives under `src/kiss_cli/integrations/`. |
| `docs/`              | User-facing documentation (rendered by DocFX via `.github/workflows/docs.yml`).              |
| `tests/`             | Pytest test suite.                                                                           |

## Making changes

1. Branch off `main` with a descriptive name.
2. Write clear, descriptive commit messages — they become the next release's
   changelog entries (see `.github/workflows/RELEASE-PROCESS.md`).
3. Run the tests before opening a PR.
4. For new presets / extensions / workflows, drop the directory into its
   top-level home. The build hook picks it up automatically; no
   `pyproject.toml` edit is needed.
5. Update docs under `docs/` when user-visible behaviour changes.

## Reporting issues

Use [GitHub Issues](https://github.com/DauQuangThanh/kiss-u/issues) for bug
reports and feature requests. Security-sensitive reports go through the
channels described in [SECURITY.md](SECURITY.md).

## Release process

Maintainer release steps live in
[.github/workflows/RELEASE-PROCESS.md](.github/workflows/RELEASE-PROCESS.md).
