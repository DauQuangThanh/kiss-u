# Feature Specification: agent-skills-system

**Feature Slug**: `agent-skills-system`
**Created**: 2026-04-26
**Updated**: 2026-04-26 (narrowed scope; subagent concerns split out
to `subagent-system/spec.md`)
**Status**: Draft (reverse-engineered)
**Mode**: auto
**Input**: `agent-skills/` (58 bundles),
`skill_assets.py:36-127`,
`agents.py:1-709`,
`integrations/base.py:682-769,892-955`,
`installer.py:497-555,301-315`,
`docs/architecture/extracted.md` §2 C4,
`docs/AI-urls.md`,
`docs/research/ai-providers-2026-04-26.md`.

## Problem Statement

kiss ships a curated library of 58 agent-skill bundles (53
`kiss-*` prefixed + 5 non-`kiss-*` per the Naming Audit
Appendix below) (e.g.
`kiss-specify`, `kiss-plan`, `kiss-clarify-specs`,
`kiss-review`, `kiss-git-feature`). For these to be usable
inside every supported AI provider's runtime, kiss must:

- store skill bundles authoritatively in one place
  (`agent-skills/` at repo root) with a stable per-skill folder
  shape (the `_template/` scaffold), conformant with the
  [agentskills.io specification](https://agentskills.io/specification);
- install each skill into the per-AI directory each provider
  expects, rendering its frontmatter and substituting the
  correct script command for the user's platform;
- bundle every skill's scripts (`scripts/bash/` +
  `scripts/powershell/`) and templates (`templates/`) alongside
  the installed `SKILL.md` so the skill is self-contained on
  disk.

Without this layer, every provider would need its own copy of
the skill texts; updates would drift across providers; and
parity between Bash and PowerShell flavours would be
unenforceable.

> **Scope split.** As of 2026-04-26 the role-agent / subagent
> concern (the 14 prompts under `subagents/` and how each AI
> exposes them as subagents / subagents / workflows) is
> covered in a separate spec: `docs/specs/subagent-system/
> spec.md`. This spec covers **skills only**.

Source evidence: `agent-skills/_template/` (scaffold);
`src/kiss_cli/skill_assets.py:36-127`
(`bundle_skill_assets`); `src/kiss_cli/agents.py:1-709`
(`CommandRegistrar` — format-aware command writer);
`src/kiss_cli/integrations/base.py:682-769` (`process_template`);
`scripts/hatch_build_hooks.py:32-71` (build-time staging,
exclusion of `_`-prefixed scaffolding folders).

## User Scenarios & Testing

### User Story 1 — Per-skill bundle layout for installed skills (Priority: P1)

As a developer running `kiss init`, I want every installed
skill in my AI tool's folder to be a self-contained directory:
`<integration>/skills/kiss-<name>/SKILL.md` plus the bundled
`scripts/bash/`, `scripts/powershell/`, and `templates/` —
because the skill at runtime needs all of those next to its
prompt.

**Why this priority**: Without per-skill bundling, slash
commands break — the skill prompt references its templates and
scripts by relative path.

**Independent test**: Run `kiss init my-project --integration
claude`; confirm `.claude/skills/kiss-specify/` contains
`SKILL.md`, `scripts/bash/common.sh`, `scripts/powershell/
common.ps1`, and `templates/spec-template.md`.

**Acceptance Scenarios**:

1. **Given** a fresh `kiss init` with a `SkillsIntegration`,
   **When** the install completes, **Then** every skill folder
   under the integration's skills root contains a `SKILL.md`
   plus the skill's `scripts/bash/`, `scripts/powershell/`,
   and `templates/` directories
   (`skill_assets.py:79-127`,
   `integrations/claude/__init__.py:42-54`).
2. **Given** the same install, **When** the user inspects a
   skill folder, **Then** the `SKILL.md` frontmatter has been
   processed (variables `{SCRIPT}`, `{ARGS}`, `__AGENT__`,
   `__CONTEXT_FILE__` substituted)
   (`integrations/base.py:682-769`).

### User Story 2 — Format-aware command rendering (Priority: P1)

As a contributor adding a skill, I want the same
`agent-skills/kiss-foo/kiss-foo.md` source file to render
correctly into the per-AI tree of every supported integration,
driven by the integration class that owns the target tree.
The supported targets (per `docs/research/ai-providers-2026-04-26.md`
and `docs/specs/integration-system/spec.md`) are:

- `.claude/skills/kiss-foo/SKILL.md` (Claude Code — SKILL folder
  layout);
- `.github/skills/kiss-foo/SKILL.md` (GitHub Copilot — SKILL
  folder);
- `.agents/skills/kiss-foo/SKILL.md` (Cursor / OpenCode / Codex
  via cross-agent fallback);
- `.cursor/skills/kiss-foo/SKILL.md` (Cursor primary);
- `.opencode/skills/kiss-foo/SKILL.md` (OpenCode primary);
- `.windsurf/skills/kiss-foo/SKILL.md` (Windsurf — SKILL folder);
- `.gemini/skills/kiss-foo/SKILL.md` (Gemini CLI — SKILL folder).

> Whether each integration's actual concrete folder + format
> matches the table above is **(unverified — confirm)** against
> the installer source — see RDEBT-026.

**Acceptance Scenarios**:

1. **Given** an integration class declaring its target folder
   and format, **When** `process_template` runs, **Then** the
   command file is rendered into the right path with the right
   format (`integrations/base.py:682-769,892-955`).
2. **Given** a `SkillsIntegration`, **When** the skill is
   installed, **Then** `bundle_skill_assets` copies the
   skill's `scripts/` and `templates/` next to the rendered
   `SKILL.md` (`skill_assets.py:79-127`).

### User Story 3 — Bash and PowerShell parity per skill (Priority: P1)

As a contributor authoring a skill, I want the project to
require both `scripts/bash/<name>.sh` and
`scripts/powershell/<name>.ps1` so the same skill works on
macOS, Linux, and Windows without a second install step.

**Acceptance Scenarios**:

1. **Given** the `_template/` scaffold, **When** a contributor
   creates a new skill from it, **Then** both
   `scripts/bash/common.sh` and `scripts/powershell/common.ps1`
   are present (`agent-skills/_template/`).
2. **Given** a skill bundle, **When** the build hook stages
   assets, **Then** every skill folder containing a `bash/`
   directory also contains a parallel `powershell/`
   directory — verified by ADR-015's parity test
   (TDEBT-021 — not yet implemented; AI suggestion —
   confirm).

### User Story 4 — Build-time exclusion of developer scaffolding (Priority: P2)

As a kiss maintainer, I want the build hook to exclude
`agent-skills/_template/` (and any `_`-prefixed directory) from
the wheel — so the developer scaffolding never ships to end
users.

**Acceptance Scenarios**:

1. **Given** the build hook runs, **When** assets are mirrored
   into `build/core_pack/`, **Then** entries whose path part
   starts with `_` are excluded
   (`scripts/hatch_build_hooks.py:51-61`).

### User Story 5 — Refresh skills on upgrade (Priority: P2)

As a developer upgrading kiss, I want every installed skill
folder to be rewritten as a unit (SKILL.md + bundled scripts +
templates) so partial upgrades cannot leave a skill in an
inconsistent state.

**Acceptance Scenarios**:

1. **Given** an existing install, **When** the user runs
   `kiss init --here --force --integration <key>`, **Then**
   each installed skill folder is rewritten in full — see
   `kiss-upgrade/spec.md` and `docs/upgrade.md:62-65`.

### User Story 6 — Frontmatter conformance to agentskills.io (Priority: P2)

As a kiss maintainer, I want every bundled skill to validate
against the agentskills.io specification: `name` matches its
parent directory, `name` is 1-64 chars
`[a-z0-9](-[a-z0-9])*`, and `description` is 1-1024 chars and
non-empty.

**Acceptance Scenarios**:

1. **Given** the 58 bundled skills, **When**
   `tests/test_agent_skills_compliance.py` and
   `.github/workflows/validate-skills.yml` run, **Then** every
   `SKILL.md` passes the agentskills.io validator (`skills-ref`).

### Edge Cases

- **Skill missing a `templates/` or `scripts/` directory**:
  `bundle_skill_assets` skips the missing source dir
  silently; the SKILL.md is still rendered. **(AI suggestion
  — confirm)**.
- **Skill with only `scripts/bash/` (no PowerShell)**: the
  parity Quality Gate (ADR-006 / ADR-015) fails review; today
  enforcement is by convention because the parity test does
  not exist (TDEBT-021 / RDEBT-005).
- **Frontmatter substitution variable missing in source**:
  `process_template` substitutes `{SCRIPT}`, `{ARGS}`,
  `__AGENT__`, `__CONTEXT_FILE__`; unknown placeholders are
  left as-is. **(AI suggestion — confirm)**.
- **Folder name collision** between two skills: not possible
  because skill ids are unique under
  `agent-skills/kiss-<name>/`.
- **Network unavailable** (offline guarantee): skill install
  reads from the bundled `core_pack/agent-skills/` — works
  offline (`tests/test_offline.py`).
- **Skill source under a `_`-prefixed directory**: excluded
  from the wheel, so it cannot be installed at runtime
  (build-time invariant).
- **Per-AI skill folder convention drift**: Cursor / Copilot /
  OpenCode advertise multiple cross-agent folders
  (`.agents/skills/`, `.claude/skills/`, etc.); kiss's choice
  per integration is **(unverified — confirm)** — RDEBT-026.

## Requirements

### Functional Requirements

- **FR-001**: The repository MUST store every skill at
  `agent-skills/kiss-<name>/` with a fixed shape: a
  `kiss-<name>.md` prompt, an optional `scripts/bash/`, an
  optional `scripts/powershell/`, and an optional
  `templates/` (CLAUDE.md "Per-skill bundles";
  `agent-skills/_template/`).
- **FR-002**: The build hook MUST mirror `agent-skills/` into
  `build/core_pack/agent-skills/`, excluding any path part
  starting with `_` (`scripts/hatch_build_hooks.py:51-61`).
- **FR-003**: At runtime, the installer MUST resolve skill
  bundles via `_locate_core_pack`
  (`installer.py:301-315`), with a fallback to the source
  checkout when running from a non-installed working copy.
- **FR-004**: For each selected integration, the installer
  MUST: render every skill template via `process_template`
  (substitute `{SCRIPT}`, `{ARGS}`, `__AGENT__`,
  `__CONTEXT_FILE__` from frontmatter)
  (`integrations/base.py:682-769`), write the rendered file in
  the integration's required format (Markdown SKILL bundle
  per agentskills.io, per
  `docs/research/ai-providers-2026-04-26.md`), and call
  `bundle_skill_assets` to copy `scripts/bash/`,
  `scripts/powershell/`, and `templates/` alongside the
  rendered file (`skill_assets.py:79-127`).
- **FR-005**: On POSIX, the installer MUST chmod every
  installed `*.sh` script executable
  (`installer.py:497-555`).
- **FR-006**: Every installed skill MUST appear in the
  per-integration manifest with a SHA-256 hash, so that
  upgrade and uninstall are diff-aware (ADR-004,
  `integrations/manifest.py:50-265`).
- **FR-007**: Skills MUST be self-contained on disk — the
  rendered prompt and the bundled `scripts/` + `templates/`
  MUST be siblings (CLAUDE.md "Per-skill bundles").
- **FR-008**: The installer MUST select script flavour per
  platform: `ps` on `os.name == 'nt'`, `sh` otherwise
  (`cli/init.py:258`); `--script` and
  `.kiss/init-options.json` MAY override per
  `kiss-install/spec.md` FR-006.
- **FR-009**: The skill-asset copy MUST NOT perform network
  I/O; assets resolve from the bundled `core_pack/`
  (`tests/test_offline.py`).
- **FR-010**: Every bundled `SKILL.md` MUST conform to the
  agentskills.io frontmatter schema (`name`, `description` —
  see `docs/research/ai-providers-2026-04-26.md`); CI gate is
  `.github/workflows/validate-skills.yml`.
- **FR-011**: The skill folder name MUST equal the
  `SKILL.md` `name:` frontmatter field, and the `name`
  MUST validate against `^[a-z0-9]+(-[a-z0-9]+)*$` with
  length 1-64 — universal across the seven supported
  providers (agentskills.io §`name`; Cursor `cursor.com/
  docs/skills`; OpenCode `opencode.ai/docs/skills/`;
  Claude Code overview).
- **FR-012**: The `description:` frontmatter field MUST be
  1-1024 chars, written in third person, and MUST state
  both **what** the skill does and **when** to invoke it.
  Trigger keywords (the user-facing phrasing the skill
  responds to) MUST be front-loaded so Codex's context-
  shortening preserves them
  (`platform.claude.com/docs/en/agents-and-tools/
  agent-skills/best-practices` "Writing effective
  descriptions"; `developers.openai.com/codex/skills`).
- **FR-013**: The `name:` field MUST NOT contain the
  reserved words `anthropic` or `claude` as tokens —
  Claude Code best-practices ban these in the `name`
  field. Skills whose current folder name violates this
  rule are listed in the Naming Audit Appendix below.
- **FR-014**: Every skill MUST be **single-purpose**. If
  the skill's `description:` requires the word "and" to
  link two distinct actions (e.g. "register changes AND
  control them"), the skill MUST be split. Per
  `developers.openai.com/codex/skills` "Keep each skill
  focused on one job" and Claude Code best-practices
  "Avoid vague names: `helper`, `utils`, `tools`".
- **FR-015**: Bare-generic skill names (`init`, `review`,
  `simplify`, `helper`, `utils`, `tools`, `security-review`,
  etc.) are FORBIDDEN at the top level of the bundled
  skill catalogue because they collide with provider built-
  in commands (Claude Code's `/init`, `/review`,
  `/security-review`). KISS-managed skills MUST use the
  `kiss-` namespace prefix; the only exemptions are
  identified in the Naming Audit Appendix below
  (Claude Code best-practices "Avoid vague names").
- **FR-016**: A bundled skill MAY include any of the
  following optional sub-directories per agentskills.io:
  `scripts/` (executable code), `references/` (additional
  docs loaded on demand), `assets/` (templates, images,
  data). KISS additionally permits `templates/` (a
  KISS-specific synonym retained for backwards-
  compatibility — same role as agentskills.io's
  `assets/templates/`).
- **FR-017**: The `kiss-` namespace prefix is RETAINED.
  No supported provider forbids it; the prefix is what
  lets `kiss integration uninstall` and `kiss upgrade`
  identify installer-managed skills without disturbing
  user-authored skills in the same `.<provider>/skills/`
  folder. ADR-019 records this decision.

### Non-Functional Requirements

- **NFR-001 (Offline)**: Skill install MUST not perform
  network I/O (ADR-003).
- **NFR-002 (Cross-platform)**: Linux, Windows; macOS
  asserted (RDEBT-005).
- **NFR-003 (Shell parity)**: Every skill MUST ship both
  Bash and PowerShell flavours (ADR-006 / ADR-015). Parity
  is a Quality Gate; the mechanical parity test is
  outstanding (TDEBT-021).
- **NFR-004 (Coverage)**: ≥ 80 % on changed files
  (RDEBT-006).
- **NFR-005 (Complexity / size)**: ≤ 40 LOC, complexity
  ≤ 10 (Principle III / RDEBT-007).
- **NFR-006 (Lint)**: Zero Ruff warnings on changed files
  (ADR-016).
- **NFR-007 (Determinism)**: Repeated installs against the
  same wheel produce manifest entries with identical
  SHA-256 hashes per file.
- **NFR-008 (Self-contained skill)**: A skill folder MUST
  contain everything it needs at runtime (prompt + scripts
  + templates), so a tar-cp of the folder works as an
  isolated unit (CLAUDE.md "Per-skill bundles").
- **NFR-009 (agentskills.io compliance)**: Skills MUST
  comply with the agentskills.io specification per
  CLAUDE.md "Agent-skills standard" — defended by
  `tests/test_agent_skills_compliance.py` and
  `.github/workflows/validate-skills.yml`.

### Key Entities

- **Skill bundle (agentskills.io shape)** — A directory
  containing **one required file** (`SKILL.md` — YAML
  frontmatter + Markdown body) plus **any of these optional
  sub-directories**: `scripts/` (executable code the agent
  can run), `references/` (additional Markdown docs loaded
  on demand), `assets/` (templates, images, data files).
  Per `agentskills.io/specification` §"Directory structure".
- **KISS-bundled skill** —
  `agent-skills/kiss-<name>/`. The KISS source-of-truth
  layout: a `kiss-<name>.md` prompt (compiled into the
  installed `SKILL.md` by the format-aware writer), plus
  optional `scripts/bash/` and `scripts/powershell/`
  (the parity-paired script flavours per ADR-006), plus
  optional `templates/` (the KISS synonym for
  agentskills.io `assets/templates/`).
- **`SKILL.md` frontmatter** — YAML block with required
  `name` and `description` fields and optional `license`,
  `compatibility` (≤ 500 chars), `metadata` (string-to-
  string map), `allowed-tools` (experimental, space-
  separated). Per `agentskills.io/specification`
  §"Frontmatter".
- **Skill scaffold** — `agent-skills/_template/`.
  Excluded from the wheel; copied by contributors when
  authoring a new skill (CLAUDE.md "Role-skill scaffolding
  template").
- **Per-AI skill install layout** — varies by integration
  but always uses the agentskills.io `SKILL.md`-folder
  shape (`docs/research/ai-providers-2026-04-26.md`):
  `.claude/skills/kiss-<name>/SKILL.md`,
  `.github/skills/kiss-<name>/SKILL.md`,
  `.cursor/skills/kiss-<name>/SKILL.md`,
  `.opencode/skills/kiss-<name>/SKILL.md`,
  `.windsurf/skills/kiss-<name>/SKILL.md`,
  `.gemini/skills/kiss-<name>/SKILL.md`,
  `.agents/skills/kiss-<name>/SKILL.md`. Concrete folder
  per integration is **(unverified — confirm)** —
  RDEBT-026.
- **`bundle_skill_assets`** —
  `skill_assets.py:36-127`. The skill-asset copier.
- **`process_template`** —
  `integrations/base.py:682-769`. The frontmatter parser +
  variable substituter.

## Success Criteria

### Measurable Outcomes

- **SC-001**: After `kiss init --integration <key>`, every
  installed skill folder contains `SKILL.md`,
  `scripts/bash/`, `scripts/powershell/`, and
  `templates/` (where the source bundle had them).
- **SC-002**: Every skill ships both Bash and PowerShell
  flavours (no skill-only-Bash or skill-only-PowerShell
  cases) — defended by the proposed parity test
  (TDEBT-021).
- **SC-003**: Every installed skill is recorded in the
  per-integration manifest with a SHA-256 hash.
- **SC-004**: Skill install performs zero network I/O —
  defended by `tests/test_offline.py`.
- **SC-005**: All bundled skills pass agentskills.io
  compliance — defended by
  `tests/test_agent_skills_compliance.py` and
  `.github/workflows/validate-skills.yml`.
- **SC-006**: For every bundled skill, the directory
  base-name equals the `SKILL.md` `name:` value (FR-011).
  Defended by an extension to
  `tests/test_agent_skills_compliance.py`.
- **SC-007**: No bundled skill's `name:` value contains
  the reserved tokens `anthropic` or `claude` (FR-013).
- **SC-008**: No bundled skill's `name:` value collides
  with a provider built-in slash command
  (`init`, `review`, `security-review`, etc.) (FR-015).
- **SC-009**: Every bundled skill's `description:` is
  non-empty, ≤ 1024 chars, third-person, and contains
  both a what-clause and a when-clause (FR-012).

## Acceptance Criteria

### Naming and structure (FR-011 … FR-017)

- **AC-N-001 (FR-011 — folder = name)** — **Given** a
  skill bundle at `agent-skills/<dir>/`, **When** the
  CI compliance test reads `<dir>/SKILL.md` (or, in the
  KISS source, the rendered `kiss-<name>.md`),
  **Then** the YAML `name:` field MUST equal `<dir>` and
  MUST match `^[a-z0-9]+(-[a-z0-9]+)*$` with length 1-64.
- **AC-N-002 (FR-012 — description quality)** —
  **Given** any bundled `SKILL.md`, **When** the
  compliance test parses the frontmatter, **Then** the
  `description:` value MUST be 1-1024 chars, MUST NOT
  start with first- or second-person pronouns ("I", "we",
  "you"), and MUST contain at least one of the trigger
  words {"Use when", "Use to", "Run when", "Invoke
  when", "for when"} (front-loaded trigger phrasing per
  Codex guidance).
- **AC-N-003 (FR-013 — no reserved words)** —
  **Given** the universe of bundled `name:` values,
  **When** the compliance test scans them, **Then** none
  may contain `anthropic` or `claude` as a hyphen-
  delimited token (case-insensitive).
- **AC-N-004 (FR-014 — single-purpose)** — **Given** a
  bundled `SKILL.md`, **When** the compliance test parses
  the `description:`, **Then** the description MUST NOT
  contain the conjunction " and " linking two distinct
  verb phrases (heuristic — flagged for human review,
  not auto-failing). Rationale: the brief calls this out
  as a code-smell.
- **AC-N-005 (FR-015 — no bare-generic names)** —
  **Given** the bundled `name:` set, **When** the
  compliance test scans the names, **Then** no `name:`
  may equal a member of the FORBIDDEN-BARE set
  {`init`, `review`, `simplify`, `helper`, `utils`,
  `tools`, `security-review`, `claude-api`} unless that
  skill is a documented exemption in the Naming Audit
  Appendix below.
- **AC-N-006 (FR-016 — bundle layout)** — **Given** a
  bundled skill directory, **When** the compliance test
  walks its children, **Then** the only directories
  permitted are `scripts/`, `references/`, `assets/`,
  and `templates/`. Any other top-level directory under
  the skill folder fails the test.
- **AC-N-007 (FR-017 — `kiss-` prefix retained)** —
  **Given** a KISS-managed bundled skill, **When** the
  installer's manifest filter runs, **Then** only
  `kiss-*` folders MAY be claimed by the installer's
  per-integration manifest; non-`kiss-*` folders that
  exist in `.<provider>/skills/` MUST NOT appear in
  the manifest (uninstall safety).

## Naming Audit Appendix

> **Status:** Proposed by ADR-019 (`Proposed`) on
> 2026-04-26. Per the brief, no rename has been applied;
> entries below are *proposals* only. NEEDS-DECISION
> rows are tracked in
> `docs/specs/requirement-debts.md` (RDEBT-029).
> The actual folder names on disk under
> `agent-skills/` REMAIN UNCHANGED — the source-side
> rename pass is deferred to a separate ADR + PR per
> the spec/code divergence rule (TDEBT-029).

### Audit method

Each current skill folder name was compared against the
adopted rules (ADR-019 §Decision):

- **Rule R1 (FR-011)** — `^[a-z0-9]+(-[a-z0-9]+)*$`,
  ≤ 64 chars, folder=name.
- **Rule R2 (FR-013)** — `name` MUST NOT contain
  `anthropic` or `claude` as tokens.
- **Rule R3 (FR-014)** — single-purpose; no overlap with
  another skill's job.
- **Rule R4 (FR-015)** — no bare-generic names; no
  collision with provider built-in commands.
- **Rule R5 (action-oriented description-line quality)** —
  the skill's `description:` should pass FR-012.
- **Rule R6 (FR-017)** — `kiss-` namespace prefix
  retained for KISS-managed skills.

### Verdict legend

- **KEEP** — current name already meets every rule.
- **RENAME** — current name violates ≥ 1 rule; a
  proposed replacement that meets all rules is offered.
- **NEEDS-DECISION** — best-practices admit two
  reasonable replacements; the human user picks. RDEBT
  logged.

### `kiss-*` skills (53 entries — every current skill listed)

| # | Current name | Verdict | Proposed name (if RENAME) | Rule cited |
|---|---|---|---|---|
| 1 | `kiss-init` | KEEP | — | R1, R4 (qualified, not bare `init`), R6 |
| 2 | `kiss-codebase-scan` | KEEP | — | R1, R3, R6 |
| 3 | `kiss-arch-extraction` | KEEP | — | R1, R3, R6 |
| 4 | `kiss-arch-intake` | KEEP | — | R1, R3, R6 |
| 5 | `kiss-c4-diagrams` | KEEP | — | R1, R3, R6 |
| 6 | `kiss-adr-author` | RENAMED (was `kiss-adr`) | — | R5 — action-oriented. Renamed 2026-04-26. |
| 7 | `kiss-tech-research` | KEEP | — | R1, R3, R6 |
| 8 | `kiss-api-docs` | KEEP | — | R1, R3, R6 |
| 9 | `kiss-dependency-map` | KEEP | — | R1, R3, R6 |
| 10 | `kiss-clarify-specs` | KEEP | — | R1, R3, R6 |
| 11 | `kiss-specify` | KEEP | — | R1, R3, R6 |
| 12 | `kiss-acceptance-criteria` | RENAMED (was `kiss-acceptance`) | — | R5 — names the artifact. Renamed 2026-04-26. |
| 13 | `kiss-feature-checklist` | RENAMED (was `kiss-checklist`) | — | R5 — qualified generic noun. Renamed 2026-04-26. |
| 14 | `kiss-plan` | KEEP | — | R1, R3, R6 |
| 15 | `kiss-taskify` | KEEP | — | R1, R3, R6 |
| 16 | `kiss-implement` | KEEP | — | R1, R3, R6 |
| 17 | `kiss-tasks-to-issues` | KEEP | — | R1, R3, R6 |
| 18 | `kiss-verify-tasks` | KEEP | — | R1, R3, R6 |
| 19 | `kiss-dev-design` | KEEP | — | R1, R3, R6 |
| 20 | `kiss-unit-tests` | KEEP | — | R1, R3, R6 |
| 21 | `kiss-test-strategy` | KEEP | — | R1, R3, R6 |
| 22 | `kiss-test-framework` | KEEP | — | R1, R3, R6 |
| 23 | `kiss-test-cases` | KEEP | — | R1, R3, R6 (single-purpose with `kiss-test-execution` per descriptions) |
| 24 | `kiss-test-execution` | KEEP | — | R1, R3, R6 |
| 25 | `kiss-regression-tests` | KEEP | — | R1, R3, R6 |
| 26 | `kiss-quality-gates` | KEEP | — | R1, R3, R6 |
| 27 | `kiss-quality-review` | KEEP | — | R1, R3, R6 |
| 28 | `kiss-security-review` | KEEP | — | R1, R3, R6 (qualifier `quality-`/`security-` distinguishes from bare `review` / `security-review`) |
| 29 | `kiss-dependency-audit` | KEEP | — | R1, R3, R6 |
| 30 | `kiss-bug-report` | KEEP | — | R1, R3, R6 |
| 31 | `kiss-bug-triage` | KEEP | — | R1, R3, R6 |
| 32 | `kiss-change-log` | RENAMED (was `kiss-change-register`) | — | R5 — more concrete noun. Renamed 2026-04-26. |
| 33 | `kiss-change-control` | KEEP | — | R3 — kept as-is; change-log vs change-control now clearly differentiated. |
| 34 | `kiss-project-planning` | RENAMED (was `kiss-pm-planning`) | — | R5 — expanded abbreviation. Renamed 2026-04-26. |
| 35 | `kiss-status-report` | KEEP | — | R1, R3, R6 |
| 36 | `kiss-risk-register` | KEEP | — | R1, R3, R6 |
| 37 | `kiss-roadmap` | KEEP | — | R1, R3, R6 |
| 38 | `kiss-backlog` | KEEP | — | R1, R3, R6 |
| 39 | `kiss-sprint-planning` | KEEP | — | R1, R3, R6 |
| 40 | `kiss-standup` | KEEP | — | R1, R3, R6 |
| 41 | `kiss-retrospective` | KEEP | — | R1, R3, R6 |
| 42 | `kiss-cicd-pipeline` | RENAMED (was `kiss-cicd`) | — | R5 — names the artifact. Renamed 2026-04-26. |
| 43 | `kiss-observability-plan` | RENAMED (was `kiss-monitoring`) | — | R5 — matches description. Renamed 2026-04-26. |
| 44 | `kiss-deployment-strategy` | RENAMED (was `kiss-deployment`) | — | R5 — matches description. Renamed 2026-04-26. |
| 45 | `kiss-infrastructure-plan` | RENAMED (was `kiss-infra`) | — | R5 — expanded abbreviation. Renamed 2026-04-26. |
| 46 | `kiss-containerization` | KEEP | — | R1, R3, R6 |
| 47 | `kiss-wireframes` | KEEP | — | R1, R3, R6 |
| 48 | `kiss-standardize` | KEEP | — | R1, R3, R6 |
| 49 | `kiss-git-feature` | KEEP | — | R1, R3, R6 |
| 50 | `kiss-git-validate` | KEEP | — | R1, R3, R6 |
| 51 | `kiss-git-remote` | KEEP | — | R1, R3, R6 |
| 52 | `kiss-git-commit` | KEEP | — | R1, R3, R6 |
| 53 | `kiss-git-initialize` | KEEP | — | R1, R3, R6 |

### Non-`kiss-` skills (5 entries)

These skills are NOT bundled in the `agent-skills/` source tree.
They are vendor built-ins provided by Claude Code or installed
via the AI tool's own skill system. They are **exempt** from the
`kiss-` namespace prefix and from the kiss installer manifest.

| # | Name | Verdict | Notes |
|---|---|---|---|
| 54 | `simplify` | EXEMPT (vendor built-in) | Not in `agent-skills/`; provided by Claude Code installation. |
| 55 | `claude-api` | EXEMPT (vendor built-in) | Not in `agent-skills/`; provided by Claude Code installation. |
| 56 | `init` | EXEMPT (vendor built-in) | Claude Code's own `/init` slash command. |
| 57 | `review` | EXEMPT (vendor built-in) | Claude Code's own `/review` slash command. |
| 58 | `security-review` | EXEMPT (vendor built-in) | Claude Code's own `/security-review` slash command. |

> **Coverage note:** the `kiss-*` table above lists all 53
> `kiss-*` skill bundles shipped in the source tree, plus the
> 5 non-`kiss-*` vendor built-in skills at rows 54-58.
> **Total: 58 audit entries.** Vendor built-ins are exempt
> from renaming (decided 2026-04-26).

### Summary counts (post-rename, 2026-04-26)

- KEEP: **44** (39 original + 5 vendor built-in exemptions)
- RENAMED: **9** (`kiss-acceptance-criteria`, `kiss-feature-checklist`,
  `kiss-project-planning`, `kiss-cicd-pipeline`,
  `kiss-observability-plan`, `kiss-deployment-strategy`,
  `kiss-infrastructure-plan`, `kiss-adr-author`,
  `kiss-change-log`)
- EXEMPT (vendor built-in): **5** (`simplify`, `claude-api`,
  `init`, `review`, `security-review`)
- NEEDS-DECISION: **0** (all resolved 2026-04-26)

## Assumptions

- Skill bundles follow the agentskills.io specification
  (CLAUDE.md "Agent-skills standard";
  `docs/research/ai-providers-2026-04-26.md`).
- The integration class encodes the per-AI directory
  convention; new providers add a subclass + registry line
  (ADR-009).
- `language.output` in `.kiss/context.yml` governs what kiss
  writes; bundled skill prompts are authored in English.

## Out of Scope

- **subagents / role-agents / subagents** — covered by
  `docs/specs/subagent-system/spec.md`.
- Authoring or editing the prompt content of bundled skills
  (developer / contributor work).
- Skill versioning across kiss versions (today every kiss
  release ships its own pinned set; no per-skill version).
- Hosting a community skill registry (skills are
  authoritative in `agent-skills/` and ship with the
  wheel).
- Programmatic invocation of installed skills outside the
  AI provider's own runtime (kiss does not run skills; AI
  providers do).
- Translating skill prompts into multiple natural
  languages.

## Traceability

- **ADRs**: ADR-002 (Hatch build hook), ADR-003 (offline),
  ADR-005 (three formats), ADR-006 (parity), ADR-009
  (static integration registry), ADR-015 (parity
  invariant), ADR-018 (narrow integration scope to seven
  AIs), **ADR-019 (agent-skill naming and structure
  aligned to provider best practices)**.
- **Source modules**:
  `src/kiss_cli/skill_assets.py:36-127`;
  `src/kiss_cli/agents.py:1-709`;
  `src/kiss_cli/integrations/base.py:682-769,892-955`;
  `src/kiss_cli/installer.py:497-555,301-315`;
  `scripts/hatch_build_hooks.py:32-71`.
- **Tests**: `tests/test_agent_skills_compliance.py`,
  `tests/test_init_multi.py`, `tests/test_offline.py`.
- **Bundled assets**: 58 skill bundles under
  `agent-skills/` (53 `kiss-*` + 5 non-`kiss-*`).
- **Research**: `docs/research/ai-providers-2026-04-26.md`,
  `docs/AI-urls.md`.
- **Related specs**: `kiss-init/spec.md` (the install
  flow), `kiss-upgrade/spec.md` (refresh flow),
  `integration-system/spec.md` (the supported-AI list and
  format families), `subagent-system/spec.md` (the
  role-agent / subagent installation flow),
  `build-and-distribution/spec.md` (the build-time
  staging).
- **Related debts**: RDEBT-005 (macOS), RDEBT-006
  (coverage), RDEBT-007 (Principle III),
  RDEBT-024 (resolved — source narrowed to 7 AIs),
  RDEBT-025 (per-AI subagent format unverified),
  RDEBT-026 (per-AI agent-file & skill-folder layout
  unverified against installer behaviour);
  **RDEBT-029 (NEEDS-DECISION naming-audit items)**;
  **RDEBT-030 (cross-provider naming-rule conflicts)**;
  **RDEBT-031 (spec/code divergence on skill renames)**;
  cross-link TDEBT-021 (parity test), TDEBT-028
  (resolved — source narrowed to 7 AIs),
  **TDEBT-029 (source-side rename pass for
  ADR-019)**.
