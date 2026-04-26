# Changelog

All notable changes to kiss are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

New entries are inserted automatically by `.github/workflows/release-trigger.yml`
below the marker comment in this file. Please keep the marker in place and write
clear, descriptive commit messages — they become the next release's changelog.

<!-- insert new changelog below this comment -->

## [Unreleased]

### Added

- **14 role-based custom agents** — architect, business-analyst,
  bug-fixer, code-quality-reviewer, code-security-reviewer, developer,
  devops, product-owner, project-manager, scrum-master,
  technical-analyst, test-architect, tester, ux-designer. Each agent
  is an AI authoring aid that delegates to role-specific skills,
  supports `interactive` / `auto` modes, and records assumptions +
  decisions to `docs/agent-decisions/<agent>/` in `auto` mode.
- **38 new `kiss-*` role skills** backing the role agents
  (`kiss-pm-planning`, `kiss-risk-register`, `kiss-c4-diagrams`,
  `kiss-adr`, `kiss-tech-research`, `kiss-dev-design`,
  `kiss-unit-tests`, `kiss-test-strategy`, `kiss-test-framework`,
  `kiss-quality-gates`, `kiss-test-cases`, `kiss-test-execution`,
  `kiss-bug-report`, `kiss-bug-triage`, `kiss-regression-tests`,
  `kiss-change-register`, `kiss-quality-review`,
  `kiss-security-review`, `kiss-dependency-audit`, `kiss-cicd`,
  `kiss-infra`, `kiss-containerization`, `kiss-monitoring`,
  `kiss-deployment`, `kiss-backlog`, `kiss-acceptance`,
  `kiss-roadmap`, `kiss-sprint-planning`, `kiss-standup`,
  `kiss-retrospective`, `kiss-codebase-scan`,
  `kiss-arch-extraction`, `kiss-api-docs`, `kiss-dependency-map`,
  `kiss-wireframes`, `kiss-arch-intake`, `kiss-status-report`,
  `kiss-change-control`). Every skill bundle ships with markdown
  prompt + templates + references + assets + Bash and PowerShell
  action scripts.
- **Shared `common.sh` / `common.ps1` helpers** for role skills:
  `read_context` (parses `.kiss/context.yml`), `worktype_dir`,
  `feature_scoped_dir`, `append_debt`, `write_decision`,
  `write_extract`, `resolve_auto`, `confirm_before_write`,
  `kiss_parse_standard_args`.
- **Agent-decisions log**: `docs/agent-decisions/<agent>/<YYYY-MM-DD>-decisions.md`
  with four kinds (`default-applied`, `alternative-picked`,
  `autonomous-action`, `debt-overridden`), written by role skills
  when running in auto mode.
- **Work-type directory convention** for all role outputs under
  `docs/`: `architecture/`, `decisions/`, `research/`, `design/`,
  `testing/`, `bugs/`, `reviews/`, `operations/`, `product/`,
  `project/`, `agile/`, `analysis/`, `ux/`. Debt files named by the
  type of debt (not the role): `tech-debts.md`, `test-debts.md`,
  `security-debts.md`, `fix-debts.md`, `pm-debts.md`, etc.
- **Developer-only scaffolding** at `agent-skills/_template/` with
  working `common.{sh,ps1}` + example action scripts. Any folder
  under `agent-skills/` whose name starts with `_` is excluded from
  the wheel by the build hook.

### Changed

- **Renamed skills** (breaking change for users of older slash
  commands):
  - `kiss-clarify` → `kiss-clarify-specs` (`/kiss.clarify` →
    `/kiss.clarify-specs`)
  - `kiss-analyze` → `kiss-verify-tasks` (`/kiss.analyze` →
    `/kiss.verify-tasks`)
  - `kiss-taskstoissues` → `kiss-tasks-to-issues`
    (`/kiss.taskstoissues` → `/kiss.tasks-to-issues`)
  - Hook names follow suit: `before_taskstoissues` →
    `before_tasks-to-issues`, `before_kiss-taskstoissues` →
    `before_kiss-tasks-to-issues`, `before_analyze` →
    `before_verify-tasks`, `before_clarify` → `before_clarify-specs`
    (and the `after_*` variants).

## [0.2.0] - 2026-04-23

### Added

- Build hook now stages the full asset tree (every preset, extension, workflow,
  template, and support script) into `src/kiss_cli/core_pack/` before packaging,
  so the published wheel works fully offline.
- Release workflow builds a wheel and sdist for every tag and attaches them to
  the GitHub Release along with a `SHA256SUMS` file.

### Changed

- `src/kiss_cli/core_pack/` is now a build-time output only; it is gitignored
  and regenerated on every `uv build`.
- `pyproject.toml` drops the hand-maintained `force-include` table in favour of
  the build hook's asset sync; adds a matching sdist `include`/`exclude` list.
