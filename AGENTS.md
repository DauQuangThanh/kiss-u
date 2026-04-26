# Project Notes for AI Assistants

## Overview

KISS is a CLI installer that bootstraps projects for Spec-Driven Development
(SDD). It ships a bundle of prompts, templates, support scripts, extensions,
presets, workflows, and AI-agent integrations that are installed into a user's
project on `kiss init`.

- Read `.kiss/context.yml`

## Key Facts

- **Source of truth for assets**: the top-level `agent-skills/`, `presets/`,
  `extensions/`, `workflows/`, and `integrations/` directories are
  authoritative. `build/core_pack/` is a build-time staging directory
  (gitignored) populated by `scripts/hatch_build_hooks.py` during `uv build`,
  then mapped into the wheel as `kiss_cli/core_pack/` via `force-include` in
  `pyproject.toml`. Do **not** edit files under `build/core_pack/` by hand.

- **Per-skill bundles**: every skill lives at
  `agent-skills/kiss-<name>/` — the folder contains the command prompt
  (`kiss-<name>.md`) plus any `scripts/` and `templates/` subdirectories
  it needs. The same folder is what `kiss init` installs into each
  agent's skill directory, so skills are self-contained on disk.

- **Role-skill scaffolding template**: `agent-skills/_template/` is the
  canonical shape for a role-skill bundle (prompt + `templates/` +
  `references/` + `assets/` + `scripts/bash/` + `scripts/powershell/`
  with shared `common.sh`/`common.ps1`). Copy it to
  `agent-skills/kiss-<name>/` when creating a new role skill. Folders
  whose name starts with `_` are developer scaffolding and are
  excluded from the installer wheel by the build hook.

- **Role-agent outputs live under work-type directories**: every custom
  agent under `subagents/` writes artefacts to
  `{paths.docs}/<work-type>/` (project-scoped) or
  `{paths.docs}/<work-type>/{current.feature}/` (feature-scoped). The
  13 work-type subdirs are fixed conventions (`architecture/`,
  `decisions/`, `research/`, `design/`, `testing/`, `bugs/`,
  `reviews/`, `operations/`, `product/`, `project/`, `agile/`,
  `analysis/`, `ux/`). Debt files are named by the type of debt, not
  by role (`tech-debts.md`, `test-debts.md`, `security-debts.md`,
  etc.). `paths.docs` is the only configurable root — the work-type
  subdirs are baked into `common.sh` / `common.ps1`, not into
  `.kiss/context.yml`.

- **AI-only scoping for role skills and custom agents**: role skills
  and custom agents are AI authoring aids, not meeting facilitators.
  They draft artefacts, ask the single human user at the keyboard for
  input, and honour `preferences.confirm_before_write`. They do **not**
  facilitate standups / sprint planning / retrospectives, interview
  third parties, negotiate with vendors, approve / sign off on
  anything, or communicate with stakeholders. Prompts must state this
  scope explicitly so the legacy "you are a PM who runs status
  meetings" framing does not leak through.

- **Every custom agent supports two modes**: `interactive` (default)
  and `auto`. Users select a mode by saying "in auto mode, …" /
  "interactively, …" in their first message, or by setting
  `KISS_AGENT_MODE=auto` in the environment. Agent mode propagates
  to the skill layer: `auto` → skill scripts run with `--auto` /
  `-Auto`; `interactive` → scripts run without the flag and the
  agent pauses for user confirmation between phases. When in `auto`,
  the agent records assumptions + non-trivial decisions to
  `{paths.docs}/agent-decisions/<agent-name>/<YYYY-MM-DD>-decisions.md`
  via the `write_decision` / `Write-Decision` helper in
  `common.sh` / `common.ps1`. Decision kinds: `default-applied`,
  `alternative-picked`, `autonomous-action`, `debt-overridden`. Debts
  and decisions are separate concepts: debts are **unresolved**
  questions the user still owes, decisions are **resolved** choices
  the AI already made on the user's behalf.

- **Output and interaction language**: `.kiss/context.yml` defines
  `language.output` (the language used for written artefacts —
  specs, plans, designs, ADRs, reviews, status reports) and
  `language.interaction` (the language used for questions,
  confirmations, and progress summaries). Both default to
  `English`. Every custom agent and skill in `interactive` mode
  must conduct its questionnaire in `language.interaction`, and
  every artefact written by any agent or skill must be authored in
  `language.output`. The two settings are independent — a user
  may read written artefacts in one language while preferring a
  different language for live conversation.

- **Multi-AI support**: the installer defaults to Claude but supports 14 AI
  providers. Users pick any combination at install time. All installations are
  project-scoped, never user-scoped.

- **Cross-platform shells**: both Bash and PowerShell are supported. The team
  works across macOS, Windows, and Linux — keep both script flavours in sync.

- **Agent-skills standard**: agent skills follow the
  [agentskills.io specification](https://agentskills.io/specification).
  Skills should minimize external dependencies.

- **Remote repository**: <https://github.com/DauQuangThanh/kiss-u>. **Do not push
  changes directly** — the user pushes manually after reviewing diffs.

- **Offline operation**: once `uv tool install` (or the wheel install) finishes,
  `kiss init` and `kiss upgrade` never touch the network. Anything that's
  needed at runtime must be in the wheel bundle.

## Guidelines

- Prefer editing existing files over creating new ones.
- When adding a new preset, extension, or workflow, drop it into its top-level
  directory; the build hook picks it up automatically — no pyproject edits.
- Ask the user for clarification whenever a suggestion or change is ambiguous.
- Make sure to run Markdown linting on all Markdown files before pushing your changes to the remote repository.
- Keep bash and powershell scripts parity.
