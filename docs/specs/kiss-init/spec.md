# Feature Specification: kiss-init

**Feature Slug**: `kiss-init`
**Created**: 2026-04-26
**Status**: Draft (reverse-engineered)
**Mode**: auto
**Input**: Reverse-engineering pass over `src/kiss_cli/cli/init.py`,
`docs/architecture/extracted.md` §5, `docs/upgrade.md`, `CLAUDE.md`.

## Problem Statement

A developer adopting Spec-Driven Development (SDD) needs a one-shot
command that scaffolds a new (or existing) project with the
prompts, skills, scripts, templates, role-agents, presets,
extensions, and workflows their chosen AI coding tools require —
without any network call after the wheel is installed, with
deterministic output, and with a manifest the project can later
upgrade or uninstall safely.

Manually copying 58 skill bundles + 14 role-agent prompts +
seven integration-specific layouts is error-prone, time-
consuming, and gets out of sync the moment kiss releases a new
version. `kiss init` takes that pain away with a single
command.

> **Supported AIs (per `docs/AI-urls.md` and ADR-018):**
> Claude Code, GitHub Copilot, Cursor Agent, OpenCode,
> Windsurf, Gemini CLI, Codex — exactly seven. The previous
> `kiro_cli`, `auggie`, `tabnine`, `kilocode`, `agy`, and
> `generic` integrations are out of scope as of 2026-04-26.
> The source code now ships exactly 7 integrations, matching
> this spec. RDEBT-024 / TDEBT-028 are resolved.

Source evidence: `src/kiss_cli/cli/init.py:76-599` (the full flow);
`docs/architecture/extracted.md:194-237` (data flow); `CLAUDE.md`
(offline-after-install, single human user); `docs/AI-urls.md`
(seven supported AIs); `docs/research/ai-providers-2026-04-26.md`
(per-AI format facts).

## User Scenarios & Testing

### User Story 1 — Scaffold a fresh project with one AI provider (Priority: P1)

As a developer starting a new project, I want to run
`kiss init my-project --integration claude` and end up with a
fully scaffolded project tree containing every Claude-specific
prompt, skill, and command file, plus `.kiss/context.yml`, plus a
fresh git repo with an initial commit, so that I can start using
SDD slash commands immediately.

**Why this priority**: This is the headline use case for kiss; if
this story works, the product delivers value on its own.

**Independent test**: Run the command in an empty parent
directory; confirm the new directory exists, contains `.kiss/`,
`.claude/skills/`, and a `.git/` with one commit; running
`/kiss.specify "test"` inside Claude Code resolves the slash
command.

**Acceptance Scenarios**:

1. **Given** an empty directory and the `kiss` CLI installed,
   **When** the user runs `kiss init my-project --integration claude`,
   **Then** a directory `my-project/` is created containing
   `.kiss/context.yml`, `.kiss/integration.json`,
   `.kiss/init-options.json`, `.kiss/integrations/claude.manifest.json`,
   `.claude/skills/kiss-*/SKILL.md`, role-agent prompts under the
   integration's agents folder, an initialised `git` repository
   with a single "initial commit", and the bundled `git`
   extension and `kiss` workflow installed
   (`cli/init.py:294-326,372-431`).
2. **Given** the same setup, **When** the user runs
   `kiss init my-project --integration unknown-key`, **Then** the
   command exits with code `1` and prints
   "Unknown integration: 'unknown-key'" plus the list of
   available integrations (`cli/init.py:117-122`).
3. **Given** a system without `git` on `PATH`, **When** the user
   runs `kiss init my-project --integration claude`, **Then** the
   command continues (does not exit) but prints
   "Git not found - will skip repository initialization" and
   no `.git/` is created (`cli/init.py:230-233`).

### User Story 2 — Initialise into the current directory with `--here` (Priority: P2)

As a developer adding kiss to an existing repository, I want to
run `kiss init --here --integration claude` (or `kiss init .`) so
that the kiss assets land in my current working directory without
forcing me to create a sub-directory.

**Why this priority**: Adding kiss to an existing project is a
common path; users with established repositories should not have
to restructure.

**Independent test**: Run in a non-empty directory; confirm the
warning appears; confirm a `y` reply proceeds and merges files.

**Acceptance Scenarios**:

1. **Given** a non-empty current directory, **When** the user
   runs `kiss init --here --integration claude` and replies `y`
   to the merge prompt, **Then** kiss merges template files into
   the directory and reports success
   (`cli/init.py:148-158`).
2. **Given** the same setup, **When** the user runs
   `kiss init --here --integration claude --force`, **Then** the
   merge proceeds without prompting (`cli/init.py:152-153`).
3. **Given** the user passes `kiss init . --integration claude`,
   **When** the command runs, **Then** behaviour is equivalent
   to `kiss init --here --integration claude`
   (`cli/init.py:125-127`).
4. **Given** the user passes both `<project_name>` and `--here`,
   **When** the command runs, **Then** the command exits with
   code `1` and prints "Cannot specify both project name and
   --here flag" (`cli/init.py:129-131`).

### User Story 3 — Multi-integration interactive selection (Priority: P2)

As a developer using more than one AI tool (e.g. Claude at home,
Copilot at work), I want to invoke `kiss init my-project` without
`--integration` and pick multiple AI providers from a multi-select
list so that one project supports them all.

**Why this priority**: Multi-AI installs are the second-most
common path; CLAUDE.md mentions this as a key product feature.

**Independent test**: Run `kiss init my-project`; press space on
two integrations; press enter; confirm both per-AI directories
exist after the run.

**Acceptance Scenarios**:

1. **Given** the user runs `kiss init my-project` (no
   `--integration`), **When** the multi-select picker appears,
   **Then** the user can toggle one or more integrations with
   space and confirm with enter (`cli/init.py:191-197`).
2. **Given** the user selects both `claude` and `copilot`,
   **When** the run completes, **Then** the project contains
   `.claude/skills/` AND `.github/skills/` (or whichever
   directory each integration owns), and the `.kiss/integration.json`
   file lists both (`cli/init.py:294-326`).

### User Story 4 — Non-interactive single-integration with options (Priority: P3)

> **Note (2026-04-26):** the previous `--integration generic`
> user story has been removed because `generic` is out of
> scope per ADR-018. The `--integration-options` flag remains
> in the CLI surface (`cli/init.py:77-87`) but applies to the
> seven supported AIs only. Passing `--integration generic`
> now exits with "Unknown integration" (removed 2026-04-26).

### User Story 5 — Install a preset during init (Priority: P3)

As a developer wanting a curated stack of skills and extensions,
I want to run `kiss init my-project --integration claude --preset lean`
so that the named preset is applied as part of the same install.

**Why this priority**: Presets are an opt-in convenience; not
every user will use them.

**Independent test**: Run with a known preset; confirm the
preset's skills appear in the install tree.

**Acceptance Scenarios**:

1. **Given** a valid preset id, **When** the user runs
   `kiss init my-project --integration claude --preset lean`,
   **Then** the preset is installed after the integration
   (`cli/init.py:466-489`).
2. **Given** an unknown preset id, **When** the user runs the
   command, **Then** the command exits with code `1` and prints
   an error.

### User Story 6 — Skip git initialisation (Priority: P3)

As a developer who manages version control with a different tool
(SVN, Mercurial, monorepo), I want to run
`kiss init my-project --integration claude --no-git` so that no
`.git/` is created.

**Why this priority**: A documented opt-out; covers the small set
of users who do not use git.

**Acceptance Scenarios**:

1. **Given** the user passes `--no-git`, **When** the command
   completes, **Then** no `.git/` directory is created
   (`cli/init.py:230-231`).

### User Story 7 — Skip AI-tool detection (Priority: P3)

As a developer scaffolding a project on a CI runner where the AI
CLI is not installed, I want to pass `--ignore-agent-tools` to
prevent kiss from aborting on the missing-CLI check.

**Acceptance Scenarios**:

1. **Given** the primary AI CLI is missing, **When** the user
   passes `--ignore-agent-tools`, **Then** the command does not
   abort on the precheck (`cli/init.py:235-253`).

### User Story 8 — Choose branch numbering scheme (Priority: P3)

As a developer who prefers timestamped feature branches, I want
to pass `--branch-numbering timestamp` so that
`.kiss/init-options.json` records that preference for downstream
SDD commands.

**Acceptance Scenarios**:

1. **Given** the user passes `--branch-numbering timestamp`,
   **When** the command completes, **Then**
   `.kiss/init-options.json` contains `"branch_numbering":
   "timestamp"` (`cli/init.py:84,441-455`).
2. **Given** the user passes an invalid value, **When** the
   command runs, **Then** it exits with code `1` and lists the
   accepted values (`cli/init.py:137-140`).

### Edge Cases

- **Target directory exists and is non-empty without `--force`**:
  `cli/init.py:172-183` prints the "Directory Conflict" panel
  and exits with code `1`.
- **Target path exists but is a regular file, not a directory**:
  `cli/init.py:163-165` exits with code `1` and prints
  "exists but is not a directory".
- **`--here` cancellation by user**: replying `n` to the merge
  prompt exits with code `0` and prints
  "Operation cancelled" (`cli/init.py:155-158`).
- **Mid-install failure with a freshly-created project dir**:
  `cli/init.py:502-507` calls `shutil.rmtree(project_path)` to
  clean up, then re-raises. With `--here=True`, no rmtree happens
  (the user's directory is preserved as-is, partially modified).
- **Network unavailable** (e.g. CI runner with no internet):
  `kiss init` MUST still complete because the wheel embeds every
  asset (`tests/test_offline.py`, `_bundled_catalogs.py:28-45`).
- **Permission denied on target dir**: behaviour is undocumented;
  expected to surface as an `OSError` and follow the rmtree-on-
  fresh-dir cleanup path. **(AI suggestion — confirm)**.
  See **RDEBT-016**.
- **Manifest mismatch on a re-run with `--here`**: see
  `kiss-upgrade/spec.md` for the upgrade flow; init does not
  re-hash existing files, it overwrites with the merge warning.
- **Multiple integrations**: both `kiss init` (multi-select)
  and `kiss integration install` (post-init) support multiple
  integrations. Each integration owns a disjoint directory tree
  and a separate manifest — see `kiss-install/spec.md`.
- **Partial multi-integration install rollback**: see
  **RDEBT-015** — when integration N succeeds and N+1 fails,
  earlier installs are not currently torn down.

## Requirements

### Functional Requirements

- **FR-001**: The CLI MUST accept a positional `PROJECT_NAME` and
  the flags `--ignore-agent-tools`, `--no-git`, `--here`,
  `--force`, `--preset`, `--branch-numbering`, `--integration`,
  `--integration-options` (`cli/init.py:77-87`).
- **FR-002**: The CLI MUST treat `kiss init .` as equivalent to
  `kiss init --here` (`cli/init.py:125-127`).
- **FR-003**: The CLI MUST reject the combination of a positional
  project name AND `--here` with exit code `1`
  (`cli/init.py:129-131`).
- **FR-004**: The CLI MUST require either `<project_name>`,
  `.`, or `--here`; passing none MUST exit with code `1`
  (`cli/init.py:133-135`).
- **FR-005**: When `--integration <key>` is supplied, the CLI MUST
  resolve `<key>` against `INTEGRATION_REGISTRY`; unknown keys
  MUST exit with code `1` and print the available list
  (`cli/init.py:117-122`).
- **FR-006**: When no `--integration` flag is supplied, the CLI
  MUST present an interactive multi-select picker of all
  registered integrations, defaulting Claude as pre-selected
  (`cli/init.py:191-197`).
- **FR-007**: The CLI MUST reject `--branch-numbering` values
  outside `{sequential, timestamp}` with exit code `1`
  (`cli/init.py:137-140`).
- **FR-008**: *(removed 2026-04-26 — `generic` integration
  removed from source per ADR-018; previously required
  `--integration-options "--commands-dir <dir>"`.)*
- **FR-009**: The CLI MUST run a tools precheck for `git` and the
  primary integration's CLI; the AI-CLI check MUST be skippable
  via `--ignore-agent-tools` (`cli/init.py:230-253`).
- **FR-010**: For each selected integration, the CLI MUST: create
  an `IntegrationManifest` (key + version + installed_at +
  per-file SHA-256), invoke the integration's `setup`, save the
  manifest at `.kiss/integrations/<key>.manifest.json`
  (`cli/init.py:294-326`,
  `integrations/manifest.py:50-265`).
- **FR-011**: The CLI MUST install shared infrastructure under
  `.kiss/` (`installer.py:393-410`).
- **FR-012**: The CLI MUST install role-agent prompts from
  `subagents/` into each integration's agent folder
  (`installer.py:429-494`).
- **FR-013**: On a fresh init, the CLI MUST write
  `.kiss/context.yml` populated from `context.py:8-152`, with
  the selected integrations under the `integrations:` key. On
  a re-init (`--here --force`), the CLI MUST merge: add new
  schema keys from the template but preserve all existing
  user-customized values (see `kiss-upgrade/spec.md` FR-016).
- **FR-014**: The CLI MUST write `.kiss/integration.json`
  (`installer.py:595-605`) and `.kiss/init-options.json`
  (`config.py:10-19`) recording the chosen integrations,
  branch numbering, and `kiss_version`.
- **FR-015**: When `--no-git` is not supplied AND `git` is
  available, the CLI MUST run `git init`, `git add`, and a first
  commit; otherwise, it MUST skip git silently and continue
  (`cli/init.py:230-231,351-398`,
  `installer.py:126-149`).
- **FR-016**: The CLI MUST auto-install the bundled `git`
  extension and the bundled `kiss` workflow at the end of init
  (`cli/init.py:372-431`).
- **FR-017**: The CLI MUST chmod `*.sh` files to be executable on
  POSIX platforms (`installer.py:497-555`).
- **FR-018**: When `--preset <id>` is supplied, the CLI MUST
  install the named preset after integrations and before the
  final summary (`cli/init.py:466-489`).
- **FR-019**: The CLI MUST display a `StepTracker` Rich tree
  showing live progress per phase (`cli/init.py:262-282`).
- **FR-020**: On any unhandled exception when `--here` is
  `False` AND the project directory was freshly created, the CLI
  MUST `shutil.rmtree(project_path)` to clean up
  (`cli/init.py:502-507`).
- **FR-021**: The CLI MUST NOT open any network socket during
  init; every asset read MUST come from the bundled
  `core_pack/` (`_bundled_catalogs.py:28-45`,
  `tests/test_offline.py`).
- **FR-022**: The CLI MUST end with a Rich tree summary and a
  Next-Steps panel (`cli/init.py:512-599`).

### Non-Functional Requirements

- **NFR-001 (Offline)**: `kiss init` MUST not perform any network
  I/O after wheel install — anchored by ADR-003 and
  `tests/test_offline.py`. Catalog updates that require network
  are out-of-scope here (see **RDEBT-023**).
- **NFR-002 (Cross-platform)**: The flow MUST work on Linux,
  Windows, and macOS (CI covers Ubuntu + Windows; macOS support
  is asserted in CLAUDE.md but not in CI — see **RDEBT-005** /
  TDEBT-014).
- **NFR-003 (Shell parity)**: Every skill installed MUST ship
  both `scripts/bash/` and `scripts/powershell/` flavours per
  ADR-006 / ADR-015.
- **NFR-004 (Coverage)**: Changed Python in `cli/init.py` MUST
  hold ≥ 80 % line coverage per Standards Quality Gates (see
  **RDEBT-006** / TDEBT-015).
- **NFR-005 (Complexity / size)**: Functions added or modified in
  `cli/init.py` MUST stay ≤ 40 executable LOC and cyclomatic
  complexity ≤ 10 per Principle III (see **RDEBT-007**).
- **NFR-006 (Lint)**: `cli/init.py` MUST pass Ruff with zero
  warnings on changed files per ADR-016.
- **NFR-007 (Performance — qualitative)**: `kiss init` MUST
  complete "within seconds" on a developer laptop on a fresh
  install (no formal SLO — see **RDEBT-002** / TDEBT-017).
- **NFR-008 (Determinism)**: Repeated runs against the same
  inputs MUST produce identical files (the manifest's per-file
  SHA-256 list MUST match), per Principle IV.
- **NFR-009 (Safety)**: The CLI MUST NOT modify files outside
  the resolved project directory or the user's git config
  (Standards' Git Safety Protocol).

### Key Entities

- **`<project_path>/.kiss/context.yml`** — project state YAML.
  Keys: `schema_version`, `paths.{docs,specs,plans,tasks,
  templates,scripts}`, `current.{feature,spec,plan,tasks,
  checklist,branch}`, `preferences.{output_format,
  task_numbering,confirm_before_write,auto_update_context}`,
  `language.{output,interaction}`, `integrations: [keys]`.
  Source: `context.py:8-152`.
- **`<project_path>/.kiss/integration.json`** —
  `{integrations: list[str], version: str}`. The former
  singular `integration` field is removed; all consumers
  MUST read the `integrations` list instead.
  Source: `installer.py:595-605`.
- **`<project_path>/.kiss/init-options.json`** — flat dict with
  `integration`, `integrations`, `branch_numbering`,
  `context_file`, `here`, `kiss_version`, `ai_skills`. Source:
  `config.py:10-19`.
- **`<project_path>/.kiss/integrations/<key>.manifest.json`** —
  per-integration manifest with `{key, version, installed_at,
  files: {rel_path: sha256}}`. Source:
  `integrations/manifest.py:50-265`.
- **Per-AI install tree** (e.g. `.claude/`, `.cursor/`,
  `.gemini/`) — owned by each integration's `setup`; see
  `agent-skills-system/spec.md`.

## Success Criteria

### Measurable Outcomes

- **SC-001**: A first-time user with no kiss experience can
  scaffold a working project (slash command resolves in their AI
  tool) by running a single `kiss init` command — no manual
  copying steps.
- **SC-002**: A user can initialise the same project on Linux
  and Windows from the same wheel and end up with byte-identical
  text-file contents (line endings normalised).
- **SC-003**: All seven supported integrations (per ADR-018
  and `integration-system/spec.md` FR-016) register in
  `INTEGRATION_REGISTRY` and produce at least one file in the
  resulting project (verified per integration in
  `tests/test_init_multi.py`). The source code now registers
  exactly 7 entries (RDEBT-024 / TDEBT-028 resolved).
- **SC-004**: Re-running `kiss init --here --force` over an
  existing kiss project produces the same on-disk state as a
  fresh install for all kiss-managed files (idempotence),
  excluding timestamps in manifests and
  `.kiss/init-options.json`. User customizations in
  `.kiss/context.yml` (e.g. `language.output`, custom
  `paths.docs`) MUST be preserved — see
  `kiss-upgrade/spec.md` FR-016.
- **SC-005**: `kiss init` performs zero network I/O — defended
  by `tests/test_offline.py`.

## Assumptions

- The user's machine has Python 3.11+ and `uv` (or another wheel-
  capable installer); kiss itself is already on `PATH` (this is
  not a "first-step bootstrap" — kiss installs *into* a project,
  not onto the machine).
- The user has either (a) installed the AI provider's CLI / IDE
  separately, OR is willing to pass `--ignore-agent-tools`.
- The standards document and ADRs apply: lint-zero-warnings,
  ≥ 80 % coverage, ≤ 40 LOC functions, parity, offline-after-
  install. Existing violations are tracked as TDEBTs and
  RDEBT-007.
- Output language is English (`.kiss/context.yml`'s
  `language.output` default).

## Out of Scope

- Authoring new skills, role-agents, or integrations (developer
  / contributor work — out of `kiss init`'s scope).
- Hosting or running the AI providers' own services — kiss only
  installs prompt and skill assets the AI tools consume locally.
- Code generation in the user's project (kiss is an installer,
  not a code-generator SDK or runtime library).
- Continuous-deployment of the user's project — kiss does not
  ship CI/CD templates beyond the SDD framework.
- Programmatic embedding of `kiss init` as a Python library
  (the surface is the CLI; the Python module is undocumented per
  `docs/analysis/api-docs.md` §2).

## Traceability

- **ADRs**: ADR-001 (CLI framework), ADR-002 (Hatch build hook),
  ADR-003 (offline after install), ADR-004 (SHA-256 manifests),
  ADR-005 (three integration formats), ADR-006 (script parity),
  ADR-009 (static integration registry), ADR-011
  (`.kiss/context.yml` as single source of project state),
  ADR-012 (two-mode UX), ADR-015 (parity invariant).
- **Source modules**:
  `src/kiss_cli/cli/init.py:76-599` (entry function and flow);
  `src/kiss_cli/installer.py:67-103,106-149,393-555,595-605`
  (helpers);
  `src/kiss_cli/context.py:8-152` (context.yml writer);
  `src/kiss_cli/config.py:10-33` (init-options.json);
  `src/kiss_cli/integrations/manifest.py:50-265` (manifests);
  `src/kiss_cli/integrations/__init__.py:14-84` (registry);
  `src/kiss_cli/skill_assets.py:36-127` (skill bundling);
  `src/kiss_cli/_bundled_catalogs.py:28-64` (offline asset
  resolution).
- **Tests**: `tests/test_init_multi.py`, `tests/test_offline.py`,
  `tests/test_asset_integrity.py`.
- **Related specs**: `kiss-upgrade/spec.md` (re-running init is
  the documented upgrade path), `integration-system/spec.md`
  (the per-integration install contract),
  `agent-skills-system/spec.md` (skill bundling),
  `preset-management/spec.md` (the `--preset` option).
- **Related debts**: RDEBT-002 (perf NFR), RDEBT-003 (asset
  integrity verification), RDEBT-005 (macOS), RDEBT-006
  (coverage threshold), RDEBT-008 (Generic commands-dir
  semantics — moot, generic removed 2026-04-26),
  RDEBT-015 (multi-integration partial rollback),
  RDEBT-016 (permission-denied behaviour),
  RDEBT-024 (resolved — source narrowed to 7 AIs);
  cross-link TDEBT-028 (resolved — source narrowed to 7 AIs).
