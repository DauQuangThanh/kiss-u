# Feature Specification: subagent-system

**Feature Slug**: `subagent-system`
**Created**: 2026-04-26
**Status**: Draft (split from `agent-skills-system/spec.md`)
**Mode**: auto
**Input**: `subagents/` (14 role-agent prompts),
`installer.py:429-494` (`install_custom_agents`),
`docs/AI-urls.md`,
`docs/research/ai-providers-2026-04-26.md`,
`CLAUDE.md` ("Role-agent outputs live under work-type
directories", "AI-only scoping", "Every custom agent supports
two modes"),
`docs/specs/integration-system/spec.md`.

## Problem Statement

kiss ships 14 role-agent prompts (architect, business-analyst,
bug-fixer, code-quality-reviewer, code-security-reviewer,
developer, devops, product-owner, project-manager, scrum-master,
technical-analyst, test-architect, tester, ux-designer) under
`subagents/`. Per the user's clarification on 2026-04-26,
**these are the "subagents" each AI provider exposes**, not
agent-skills. Different providers call the same surface
different things:

- **Claude Code** — *subagents* (`.claude/agents/`).
- **GitHub Copilot** — *custom agents* (`.github/agents/` /
  `.claude/agents/` — VS Code Copilot terminology).
- **Cursor Agent** — *subagents* (`.cursor/agents/`).
- **OpenCode** — *agents* with `mode: subagent`
  (`.opencode/agents/`).
- **Windsurf** — *workflows* (`.windsurf/workflows/`); the
  closest analogue, with a 12 000-char file size limit and
  manual `/<workflow-name>` invocation.
- **Gemini CLI** — *subagents* (`.gemini/agents/`).
- **Codex** — *subagents* (`.codex/agents/`, TOML format).

The kiss installer must:

- store role-agent prompts authoritatively at
  `subagents/<role>.md` (one Markdown file per role);
- install each prompt into the per-AI subagent folder, in the
  format that AI expects (Markdown for six providers, TOML for
  Codex);
- write the per-AI agent context file (`CLAUDE.md`,
  `AGENTS.md`, or `GEMINI.md` per
  `docs/research/ai-providers-2026-04-26.md`);
- propagate the two-mode UX (`interactive` / `auto`) into each
  installed prompt, per ADR-012 / CLAUDE.md "Every custom
  agent supports two modes";
- honour the work-type output convention so every role-agent
  writes artefacts under `{paths.docs}/<work-type>/` (or
  `{paths.docs}/<work-type>/{current.feature}/`) without
  needing per-role configuration.

Without this layer, role-agents would be authored once and
installed manually per provider, drifting across AIs and
breaking the "single project, many AI tools" promise.

> **Scope split.** This spec is paired with
> `docs/specs/agent-skills-system/spec.md`. The skills system
> covers the agent-skills bundles (`agent-skills/kiss-*`); this
> spec covers the role-agent prompts (`subagents/<role>.md`)
> only. The two specs **do not have overlapping FRs**.

Source evidence: `subagents/<role>.md` (14 files);
`src/kiss_cli/installer.py:429-494` (`install_custom_agents`);
`CLAUDE.md` (work-type dirs, two-mode UX, output / interaction
language); `docs/research/ai-providers-2026-04-26.md` (per-AI
subagent format).

## User Scenarios & Testing

### User Story 1 — Install role-agent prompts as subagents per AI (Priority: P1)

As a developer running `kiss init`, I want each of the 14
role-agent prompts under `subagents/` to be installed as a
subagent (or that AI's equivalent) inside the integration's
agent folder, in the file format that AI expects.

**Why this priority**: Headline value — without this, the user
has to copy 14 prompts manually for each AI tool they use.

**Independent test**: Run `kiss init my-project --integration
claude`; confirm `.claude/agents/architect.md`,
`.claude/agents/developer.md`, … exist with the role prompts.

**Acceptance Scenarios**:

1. **Given** a fresh `kiss init` with one of the seven
   supported integrations selected, **When** the run completes,
   **Then** `installer.py:429-494` (`install_custom_agents`)
   has copied each `subagents/<role>.md` into the
   integration's subagent folder, using the per-AI naming and
   format from `docs/research/ai-providers-2026-04-26.md`
   (`(unverified — confirm against installer source code; see
   RDEBT-027)`).
2. **Given** the same install, **When** the user inspects the
   installed subagent file, **Then** the YAML frontmatter
   contains the per-AI required fields (e.g. Claude /
   Cursor / Gemini: `name`, `description`; Codex TOML:
   `name`, `description`, `developer_instructions`); body
   contains the role prompt
   `(unverified — confirm)`.

### User Story 2 — Per-AI agent file is written / refreshed (Priority: P1)

As a developer running `kiss init`, I want kiss to write the
agent context file each AI expects at the project root, so the
AI tool finds its top-level instructions.

The supported agent files (per
`docs/research/ai-providers-2026-04-26.md`):

| Integration | Agent file at project root |
|---|---|
| Claude Code | `CLAUDE.md` |
| GitHub Copilot | `AGENTS.md` |
| Cursor Agent | `AGENTS.md` |
| OpenCode | `AGENTS.md` |
| Windsurf | `AGENTS.md` |
| Gemini CLI | `GEMINI.md` |
| Codex | `AGENTS.md` |

**Acceptance Scenarios**:

1. **Given** a fresh `kiss init --integration <key>` for any
   of the seven supported AIs, **When** the install completes,
   **Then** the appropriate agent file (`CLAUDE.md`,
   `AGENTS.md`, or `GEMINI.md`) exists at the project root
   `(unverified — confirm against installer; RDEBT-026)`.
2. **Given** an upgrade with `kiss init --here --force`, **When**
   the upgrade runs, **Then** only the kiss-managed block
   (between `<!-- KISS START -->` and `<!-- KISS END -->`) is
   rewritten; content outside the markers is preserved
   (`docs/upgrade.md:62-65`; cross-spec to `kiss-upgrade/
   spec.md` FR-013).

### User Story 3 — Two-mode UX propagated to subagents (Priority: P1)

As a developer who prefers fully-automated runs, I want each
installed subagent to support `interactive` (default) and
`auto` modes per CLAUDE.md "Every custom agent supports two
modes" and ADR-012, with `auto` mode driven by the
`KISS_AGENT_MODE=auto` environment variable or a "in auto
mode, …" prefix in the user's first message.

**Acceptance Scenarios**:

1. **Given** a subagent's installed prompt file, **When** the
   user reads it, **Then** the prompt contains the two-mode
   UX clause and the decision-log instruction (write to
   `{paths.docs}/agent-decisions/<agent-name>/<YYYY-MM-DD>-
   decisions.md` via the `write_decision` helper)
   `(unverified — confirm; RDEBT-028)`.
2. **Given** a subagent in `auto` mode, **When** the agent
   takes a default-applied / alternative-picked / autonomous-
   action / debt-overridden decision, **Then** the agent
   writes a row to its decision log per CLAUDE.md.

### User Story 4 — Work-type output directories honoured (Priority: P2)

As a developer using role-agents, I want each agent's output
artefact to land under the correct work-type directory
(`{paths.docs}/architecture/`,
`{paths.docs}/decisions/`, `{paths.docs}/research/`,
`{paths.docs}/design/`, `{paths.docs}/testing/`,
`{paths.docs}/bugs/`, `{paths.docs}/reviews/`,
`{paths.docs}/operations/`, `{paths.docs}/product/`,
`{paths.docs}/project/`, `{paths.docs}/agile/`,
`{paths.docs}/analysis/`, `{paths.docs}/ux/`) per CLAUDE.md
"Role-agent outputs live under work-type directories".

The 13 work-type subdirs are baked into the shared
`scripts/bash/common.sh` and `scripts/powershell/common.ps1`
helpers; `paths.docs` is the only configurable root and lives
in `.kiss/context.yml`.

**Acceptance Scenarios**:

1. **Given** the `architect` subagent runs and produces an
   ADR, **When** the agent calls the shared helper to compute
   the output path, **Then** the helper resolves to
   `{paths.docs}/decisions/ADR-NNN-<slug>.md`
   `(unverified — confirm)`.
2. **Given** any of the 14 subagents, **When** the agent
   computes its output dir, **Then** it MUST resolve via the
   shared helpers in `common.sh` / `common.ps1`, not by a
   hard-coded constant in the prompt.

### User Story 5 — AI-only scoping is respected (Priority: P2)

As a developer using kiss subagents, I want each subagent to
behave as an AI authoring aid (drafts artefacts, asks the
single user at the keyboard for input, honours
`preferences.confirm_before_write`), not as a meeting
facilitator, vendor negotiator, stakeholder communicator, or
sign-off authority. This is the explicit scope per CLAUDE.md
"AI-only scoping for role skills and custom agents".

**Acceptance Scenarios**:

1. **Given** any installed subagent prompt, **When** the user
   reads it, **Then** the prompt explicitly states the
   AI-only scope and excludes meeting facilitation,
   third-party interviews, vendor negotiation, sign-off, and
   external communication
   `(unverified — confirm; RDEBT-028)`.

### User Story 6 — Refresh subagents on upgrade (Priority: P2)

As a developer upgrading kiss, I want each installed subagent
prompt to be rewritten as a unit when the bundled
`subagents/` content changes, with the manifest's hash
check protecting any user-edited subagent prompt unless
`--force` is supplied.

**Acceptance Scenarios**:

1. **Given** an existing install with no user edits, **When**
   `kiss integration upgrade <key>` runs, **Then** every
   subagent prompt is rewritten from the bundled
   `core_pack/subagents/`
   (`integrations/manifest.py:50-265`).
2. **Given** the user has edited a subagent prompt, **When**
   the upgrade runs without `--force`, **Then** the upgrade
   lists the modified file and aborts (cross-spec to
   `kiss-upgrade/spec.md` FR-005).

### User Story 7 — Subagent naming + structure follow provider best practices (Priority: P2)

As a developer running `kiss init` against any of the seven
supported AIs, I want every installed subagent to validate
against that AI's published naming + frontmatter rules
(per ADR-020), so the AI's delegation logic ranks KISS
subagents reliably and the role-agent prompts don't get
silently dropped or merged with user-authored agents.

**Acceptance Scenarios** *(ADR-020)*:

1. **Given** any of the 14 bundled role-agent prompts
   under `subagents/`, **When** the prompt is
   inspected, **Then** the basename validates against
   `^[a-z0-9]+(-[a-z0-9]+)*$`, length ≤ 64 chars
   (FR-012). All 14 currently pass.
2. **Given** the bundled YAML frontmatter, **When**
   parsed, **Then** the `name:` value equals the
   basename minus `.md` (FR-012). All 14 currently
   pass.
3. **Given** the per-provider rendering on install
   (FR-014), **When** the user inspects
   `.claude/agents/architect.md`,
   `.github/agents/architect.agent.md`,
   `.cursor/agents/architect.md`,
   `.opencode/agents/architect.md`,
   `.windsurf/workflows/architect.md`,
   `.gemini/agents/architect.md`, and
   `.codex/agents/architect.toml` after a multi-AI
   `kiss init`, **Then** each file conforms to that
   provider's frontmatter / format rules listed in
   §FR-014 / Key Entities. Verification is
   `(unverified — confirm)` per RDEBT-027 +
   RDEBT-035.
4. **Given** a subagent on Windsurf, **When** the
   bundled prompt exceeds 12 000 chars, **Then** the
   installer trims non-essential content (examples,
   long Bash recipes) before stripping the two-mode
   UX, AI-only scope, or decision-log clauses
   (FR-017 + RDEBT-025).
5. **Given** a subagent on OpenCode, **When** the
   user inspects `.opencode/agents/<role>.md`,
   **Then** the frontmatter contains
   `mode: subagent` (FR-014). Today
   `(unverified — confirm)` per RDEBT-027.
6. **Given** any role-agent prompt's `description:`
   field, **When** read, **Then** the description is
   ≤ 1024 chars (FR-015). All 14 currently pass.
   The recommended length (200–600 chars) is **NOT**
   met by the current 14 prompts; the tightening
   pass is logged as RDEBT-034.

### Edge Cases

- **Integration without an agent folder convention**: today's
  installer logic for choosing the target dir per AI is
  **(unverified — confirm)** — RDEBT-027 supersedes the older
  RDEBT-020.
- **Codex TOML conversion**: the bundled `<role>.md` is
  Markdown; for Codex, the installer needs to render to TOML
  per `docs/research/ai-providers-2026-04-26.md`. Whether the
  current installer does this is **(unverified — confirm)** —
  RDEBT-027.
- **Windsurf 12 000-char workflow limit**: a verbose role
  prompt may exceed the limit; behaviour
  **(unverified — confirm)** — flagged in RDEBT-025.
- **Per-AI naming convention drift**: Cursor / Gemini accept
  hyphens + underscores in subagent `name`; Codex needs both
  filename and `name` field aligned. Coverage is
  **(unverified — confirm)** — RDEBT-027.
- **Network unavailable**: subagent install reads from bundled
  `core_pack/subagents/` — works offline
  (`tests/test_offline.py`).
- **Agent context file already contains user content**: the
  upgrade flow MUST refresh only the
  `<!-- KISS START --> … <!-- KISS END -->` block — see
  `kiss-upgrade/spec.md` FR-013.

## Requirements

### Functional Requirements

- **FR-001**: The repository MUST store every role-agent
  prompt at `subagents/<role>.md` (Markdown +
  YAML / front-matter as authored). The 14 roles are listed
  in **Key Entities**
  (`subagents/architect.md`, …,
  `subagents/ux-designer.md`).
- **FR-002**: The build hook MUST mirror `subagents/`
  into `build/core_pack/subagents/`
  (`scripts/hatch_build_hooks.py:32-48`).
- **FR-003**: For each selected integration in the supported
  set (per `integration-system/spec.md` FR-016 / FR-017), the
  installer MUST copy / render every
  `subagents/<role>.md` into the integration's subagent
  folder, in the format that AI expects, per
  `docs/research/ai-providers-2026-04-26.md`. The exact
  per-AI mapping (folder, file extension, frontmatter shape)
  is captured in **Key Entities** below; whether the
  installer source matches the mapping is
  **(unverified — confirm)** — RDEBT-027.
- **FR-004**: The installer MUST write the per-AI agent file
  at the project root: `CLAUDE.md` (Claude Code), `AGENTS.md`
  (Copilot / Cursor / OpenCode / Windsurf / Codex),
  `GEMINI.md` (Gemini CLI). The installer MAY use the
  `<!-- KISS START -->` / `<!-- KISS END -->` markers to
  delimit the kiss-managed block
  `(unverified — confirm; RDEBT-026)`.
- **FR-005**: Each installed subagent prompt MUST contain the
  two-mode UX clause (interactive default; auto via
  `KISS_AGENT_MODE=auto` or "in auto mode, …" prefix) per
  CLAUDE.md and ADR-012. In `auto` mode, the agent MUST log
  decisions to
  `{paths.docs}/agent-decisions/<agent-name>/<YYYY-MM-DD>-
  decisions.md` (kinds: `default-applied`,
  `alternative-picked`, `autonomous-action`, `debt-overridden`).
- **FR-006**: Each installed subagent prompt MUST resolve its
  output directory via the shared helpers in
  `scripts/bash/common.sh` and `scripts/powershell/common.ps1`
  (i.e. one of the 13 work-type subdirs under `paths.docs`).
  Hard-coded output paths in role prompts are forbidden.
- **FR-007**: Each installed subagent prompt MUST honour
  `language.output` and `language.interaction` from
  `.kiss/context.yml`: written artefacts in `language.output`,
  questions / confirmations / progress summaries in
  `language.interaction`. Both default to `English`.
- **FR-008**: Each installed subagent prompt MUST state the
  AI-only scope (no meeting facilitation, no third-party
  interviews, no vendor negotiation, no sign-off, no
  stakeholder communication) per CLAUDE.md.
- **FR-009**: Every installed subagent file MUST appear in
  the per-integration manifest with a SHA-256 hash, so that
  upgrade and uninstall are diff-aware (ADR-004,
  `integrations/manifest.py:50-265`).
- **FR-010**: The subagent install MUST NOT perform network
  I/O; assets resolve from `core_pack/subagents/`
  (`tests/test_offline.py`).
- **FR-011**: When refreshing the per-AI agent context file
  during upgrade, the installer MUST only rewrite the block
  between `<!-- KISS START -->` and `<!-- KISS END -->`;
  content outside the markers MUST be preserved (cross-spec
  to `kiss-upgrade/spec.md` FR-013).
- **FR-012** *(ADR-020)*: Every bundled role-agent prompt
  filename MUST be `<role>.md` in lowercase + hyphens, with
  the basename validating against
  `^[a-z0-9]+(-[a-z0-9]+)*$`, length ≤ 64 chars. The
  `name:` field of the YAML frontmatter MUST equal the
  basename without the extension.
- **FR-013** *(ADR-020)*: Every bundled role-agent prompt
  MUST carry a YAML frontmatter block with at least
  `name` and `description`. The Claude Code-shaped optional
  fields (`tools`, `model`, `color`) MAY be present in the
  bundled prompt; the installer is responsible for
  rendering the per-provider shape on install (FR-014).
- **FR-014** *(ADR-020)*: The installer MUST render each
  role-agent prompt to the per-provider shape on install,
  per the table in **Key Entities → Per-AI subagent
  install layout**:
  - **Claude Code** — copy `<role>.md` verbatim into
    `.claude/agents/`; YAML frontmatter is preserved
    as authored.
  - **Copilot** — write `<role>.agent.md` into
    `.github/agents/`; frontmatter MAY be filtered to
    Copilot-supported keys (`name`, `description`,
    `tools`, `model`, `agents`, `handoffs`).
  - **Cursor** — write `<role>.md` into
    `.cursor/agents/`; frontmatter MAY be filtered to
    Cursor-supported keys (`name`, `description`,
    `model`, `readonly`, `is_background`).
  - **OpenCode** — write `<role>.md` into
    `.opencode/agents/`; frontmatter MUST include
    `mode: subagent`. Filter to OpenCode-supported
    keys (`description`, `mode`, `model`, `permission`,
    `color`).
  - **Windsurf** — write `<role>.md` into
    `.windsurf/workflows/`; STRIP the YAML
    frontmatter (Windsurf workflows are plain
    Markdown). Cap output length at 12 000 chars per
    `RDEBT-025`; the two-mode UX, AI-only scope, and
    decision-log clauses (FR-005 / FR-006 / FR-008)
    MUST be preserved before any other content is
    trimmed.
  - **Gemini CLI** — write `<role>.md` into
    `.gemini/agents/`; frontmatter MAY be filtered to
    Gemini-supported keys (`name`, `description`,
    `kind`, `tools`, `mcpServers`, `model`).
  - **Codex** — render to `<role>.toml` in
    `.codex/agents/`; required keys: `name`,
    `description`, `developer_instructions` (the
    Markdown body); optional `model`,
    `model_reasoning_effort`, `sandbox_mode`,
    `mcp_servers`. Verification of the current
    installer's compliance is **(unverified —
    confirm)** per RDEBT-027.
- **FR-015** *(ADR-020)*: Every role-agent
  `description:` MUST be third-person, front-load the
  trigger phrase, state what the agent does AND when
  to invoke it, and disambiguate from sibling agents
  (e.g. `tester` vs `test-architect`). Hard cap:
  ≤ 1024 chars (the agentskills.io / Claude Code
  limit); recommended length 200–600 chars. Current
  bundled descriptions exceed the recommended length;
  the tightening pass is logged as **RDEBT-034**.
- **FR-016** *(ADR-020)*: Every role-agent prompt MUST
  be **single-purpose** — if the description requires
  the word "and" between two distinct responsibilities,
  the agent SHOULD be re-scoped or split. The current
  14 are coherent under their role label; no split is
  mandated by ADR-020.
- **FR-017** *(ADR-020)*: Two-mode UX clause
  (`interactive` default; `auto` via `KISS_AGENT_MODE=auto`
  or "in auto mode, …" prefix), AI-only scope clause,
  and decision-log path
  (`{paths.docs}/agent-decisions/<agent-name>/<YYYY-MM-DD>-decisions.md`)
  MUST be preserved verbatim under every per-provider
  rendering (FR-014). The Windsurf 12 000-char
  ceiling does NOT exempt these three clauses.
- **FR-018** *(ADR-020)*: Subagent names MUST NOT carry a
  `kiss-` prefix. Unlike skills (ADR-019 §9), subagent
  folders are project-managed by the user; the
  collision risk against built-in provider agents is
  documented in RDEBT-033 and is not solved by a
  prefix. Codex's reserved names (`default`, `worker`,
  `explorer`) MUST NOT be used as KISS subagent
  names; the current 14 do not collide.

### Non-Functional Requirements

- **NFR-001 (Offline)**: Subagent install MUST not perform
  network I/O (ADR-003).
- **NFR-002 (Cross-platform)**: Linux, Windows; macOS
  asserted (RDEBT-005).
- **NFR-003 (Coverage)**: ≥ 80 % on changed files
  (RDEBT-006).
- **NFR-004 (Complexity / size)**: ≤ 40 LOC, complexity
  ≤ 10 (Principle III / RDEBT-007).
- **NFR-005 (Lint)**: Zero Ruff warnings on changed files
  (ADR-016).
- **NFR-006 (Determinism)**: Repeated installs against the
  same wheel produce manifest entries with identical
  SHA-256 hashes per file.
- **NFR-007 (AI-only scope)**: Every subagent's prompt MUST
  state the AI-only scope explicitly (FR-008).
- **NFR-008 (Output language)**: Every subagent honours
  `.kiss/context.yml` `language.output` /
  `language.interaction` defaults (FR-007).

### Key Entities

- **Role-agent prompt** —
  `subagents/<role>.md`. The 14 roles:
  `architect`, `bug-fixer`, `business-analyst`,
  `code-quality-reviewer`, `code-security-reviewer`,
  `developer`, `devops`, `product-owner`,
  `project-manager`, `scrum-master`, `technical-analyst`,
  `test-architect`, `tester`, `ux-designer`.
- **Per-AI subagent install layout** (per
  `docs/research/ai-providers-2026-04-26.md`):

  | Integration | Subagent target | Format |
  |---|---|---|
  | `claude` (Claude Code) | `.claude/agents/<role>.md` | Markdown + YAML frontmatter (`name`, `description`, optional `tools`, `model`) |
  | `copilot` (GitHub Copilot) | `.github/agents/<role>.agent.md` (VS Code Copilot custom agents) | Markdown + YAML frontmatter (`name`, `description`, optional `tools`, `model`, `agents`, `handoffs`) |
  | `cursor_agent` (Cursor) | `.cursor/agents/<role>.md` | Markdown + YAML frontmatter (`name`, `description`, optional `model`, `readonly`, `is_background`) |
  | `opencode` (OpenCode) | `.opencode/agents/<role>.md` with `mode: subagent` | Markdown + YAML frontmatter (`description` required, `mode`, optional `model`, `temperature`, `permission`) |
  | `windsurf` (Windsurf workflows ≈ subagents) | `.windsurf/workflows/<role>.md`, ≤ 12 000 chars, invoked `/<role>` | Markdown |
  | `gemini` (Gemini CLI) | `.gemini/agents/<role>.md` | Markdown + YAML frontmatter (`name`, `description`, optional `kind`, `tools`, `mcpServers`, `model`) |
  | `codex` (Codex) | `.codex/agents/<role>.toml` | TOML (`name`, `description`, `developer_instructions`, optional `nickname_candidates`, `model`, `model_reasoning_effort`, `sandbox_mode`, `mcp_servers`, `skills.config`) |

- **Per-AI agent file** (one of `CLAUDE.md`, `AGENTS.md`,
  `GEMINI.md` at project root — see User Story 2 / FR-004).
- **`install_custom_agents`** —
  `installer.py:429-494`. The role-agent installer.
- **Two-mode UX clause** — boilerplate stating
  `interactive` vs `auto` triggers, decision-log path, and
  decision kinds (`default-applied`,
  `alternative-picked`, `autonomous-action`,
  `debt-overridden`). Required in every prompt per
  CLAUDE.md.
- **Work-type subdirs** — fixed list of 13 directories
  under `{paths.docs}` (`architecture/`, `decisions/`,
  `research/`, `design/`, `testing/`, `bugs/`, `reviews/`,
  `operations/`, `product/`, `project/`, `agile/`,
  `analysis/`, `ux/`).
- **Subagent prompt anatomy** *(ADR-020)* — every
  bundled `<role>.md` MUST contain three layers:
  1. **YAML frontmatter** (`name`, `description`,
     optional `tools`, `model`, `color`); the
     installer renders the per-provider shape per
     FR-014.
  2. **Markdown body** — the role-agent system
     prompt, including the AI authoring scope
     section (`## AI authoring scope` with does /
     does-not bullets), the two-mode UX clause, the
     decision-log instruction, and the language
     instruction (`language.output` /
     `language.interaction` from `.kiss/context.yml`).
  3. **Handover contract** — explicit cross-spec
     references to skills the agent invokes (e.g.
     `architect` → `kiss-arch-intake`,
     `kiss-tech-research`, `kiss-adr`,
     `kiss-c4-diagrams`). The handover contract is
     informational; it does NOT change the
     installer's rendering.

## Success Criteria

### Measurable Outcomes

- **SC-001**: After `kiss init --integration <key>` for any
  of the seven supported AIs, all 14 role-agent prompts
  are present in the integration's subagent folder in the
  AI's expected format
  `(unverified — confirm; RDEBT-027)`.
- **SC-002**: Every installed subagent appears in the
  per-integration manifest with a SHA-256 hash (FR-009).
- **SC-003**: The per-AI agent file (`CLAUDE.md`,
  `AGENTS.md`, or `GEMINI.md`) exists at project root and
  the kiss-managed block is delimited by
  `<!-- KISS START --> … <!-- KISS END -->`
  `(unverified — confirm; RDEBT-026)`.
- **SC-004**: Each installed subagent prompt contains the
  two-mode UX clause and the AI-only scope statement
  `(unverified — confirm; RDEBT-028)`.
- **SC-005**: Subagent install performs zero network I/O —
  defended by `tests/test_offline.py`.

## Assumptions

- The seven supported AI providers are listed in
  `integration-system/spec.md` FR-016 / FR-017 and in
  `docs/research/ai-providers-2026-04-26.md`. Extending the
  list requires a new ADR (cross-link to ADR-018).
- Per-AI subagent format facts in **Key Entities** are
  derived from `docs/AI-urls.md` WebFetch on 2026-04-26;
  format gaps are flagged as `(unverified — confirm)` and
  logged as RDEBTs.
- The 14 role-agent prompts under `subagents/` are
  authored in English; per-user language is governed by
  `.kiss/context.yml` (FR-007).
- The integration class encodes the per-AI directory and
  format convention; the static registry is governed by
  ADR-009 + ADR-018.

## Out of Scope

- **Agent-skills bundles** (the `agent-skills/kiss-*`
  library) — covered by
  `docs/specs/agent-skills-system/spec.md`.
- Authoring or editing the prompt content of bundled
  role-agents (developer / contributor work).
- Cross-AI coordination of subagents (e.g. an architect
  subagent in Claude calling a developer subagent in
  Cursor) — outside kiss's scope; each AI runs its own
  subagent stack.
- Conversion / translation of `subagents/<role>.md`
  prompts into multiple natural languages.
- Subagent runtime telemetry (kiss does not run
  subagents; each AI provider does).

## Naming Audit Appendix *(ADR-020)*

Audit pass performed on 2026-04-26 against the seven
WebFetched provider docs (see ADR-020 §Traceability).
Each of the 14 bundled role-agent prompts under
`subagents/` is graded:

- **KEEP** — current name + structure meets every
  documented best practice cited in ADR-020.
- **RENAME** — current name violates a published
  rule; replacement proposed with rule citation.
- **NEEDS-DECISION** — providers disagree on a rule
  the user must pick a winner for, or two reasonable
  names exist. Logged as a new RDEBT.

| # | Current name | Verdict | Rationale / cite | Proposed name | RDEBT |
|---|---|---|---|---|---|
| 1 | `architect` | NEEDS-DECISION | Cursor / Copilot prefer role-oriented (KEEP); OpenCode / Codex prefer action-oriented (`design-architecture` / `architect-system`). Single-English-word role name carries collision risk against future built-in agents (Codex reserves `default`/`worker`/`explorer`; no current Claude Code reservation). | `architect` (KEEP) **OR** `kiss-architect` (prefix per RDEBT-033) **OR** `design-architecture` (action-oriented per RDEBT-032) | RDEBT-032 + RDEBT-033 |
| 2 | `bug-fixer` | KEEP | Hyphenated kebab-case, single-purpose, action-flavoured ("fix bugs"). Validates against `^[a-z0-9]+(-[a-z0-9]+)*$`. No collision with built-ins. | — | — |
| 3 | `business-analyst` | KEEP | Hyphenated, role-oriented (Cursor / Copilot preference). Long (16 chars) but well under the 64-char cap. Description tightening pending (RDEBT-034). | — | RDEBT-034 |
| 4 | `code-quality-reviewer` | KEEP (with sibling-disambiguation tightening) | Compound name disambiguates from `code-security-reviewer`. The two siblings BOTH need their `description:` first sentence to front-load the differentiator (quality vs security) — RDEBT-034. Cursor's `readonly: true` should be set on install per ADR-020 §5. | — | RDEBT-034 |
| 5 | `code-security-reviewer` | KEEP (with sibling-disambiguation tightening) | Same reasoning as code-quality-reviewer. Cursor's `readonly: true` applies. | — | RDEBT-034 |
| 6 | `developer` | NEEDS-DECISION | Single English word, very generic. No documented Claude Code / Cursor / OpenCode reservation today, but the name is the kind of bare-generic that Cursor's "avoid vague descriptions" anti-pattern flags by extension. RENAME-to-namespaced (`kiss-developer`) would resolve collision risk; RENAME-to-action (`develop-features`) follows OpenCode / Codex preference. | `developer` (KEEP) **OR** `kiss-developer` **OR** `develop-features` | RDEBT-032 + RDEBT-033 |
| 7 | `devops` | NEEDS-DECISION | Single token, role-oriented. The name is widely understood (DevOps / SRE / platform engineering) and short. Lowercase + no hyphen passes the regex but reads as a brand-name, not a kebab-case identifier. Style alternatives: KEEP, `dev-ops`, `kiss-devops`, `platform-ops`. | `devops` (KEEP) **OR** `kiss-devops` (prefix) **OR** `platform-ops` (action-oriented) | RDEBT-032 + RDEBT-033 |
| 8 | `product-owner` | KEEP | Hyphenated kebab-case, role-oriented (Scrum ceremony role). The siblings (`product-owner` / `project-manager` / `scrum-master`) are functionally distinct per Scrum / PMI conventions; descriptions need to front-load the differentiator (RDEBT-034). | — | RDEBT-034 |
| 9 | `project-manager` | KEEP (with sibling-disambiguation tightening) | Hyphenated kebab-case, role-oriented. PMI-flavoured complement to product-owner / scrum-master. | — | RDEBT-034 |
| 10 | `scrum-master` | KEEP (with sibling-disambiguation tightening) | Hyphenated kebab-case, Scrum role. | — | RDEBT-034 |
| 11 | `technical-analyst` | KEEP | Hyphenated kebab-case. The role is "code archaeology / reverse engineering" — the description front-loads this and is the clearest of the 14, so disambiguation effort is lower. | — | RDEBT-034 |
| 12 | `test-architect` | KEEP (with sibling-disambiguation tightening) | Hyphenated kebab-case. Sibling `tester` covers execution; `test-architect` covers strategy + framework selection. Descriptions need to front-load the differentiator (RDEBT-034). | — | RDEBT-034 |
| 13 | `tester` | NEEDS-DECISION | Single English word. Same kind of bare-generic as `developer`. Collision risk with user-authored or built-in `tester` agents. Style alternatives: KEEP, `kiss-tester`, `manual-tester`, `feature-tester`. | `tester` (KEEP) **OR** `kiss-tester` **OR** `feature-tester` | RDEBT-032 + RDEBT-033 |
| 14 | `ux-designer` | KEEP | Hyphenated kebab-case, role-oriented. No collision risk. Description tightening still applies (RDEBT-034). | — | RDEBT-034 |

**Audit verdict counts:**

- **KEEP** — 10 of 14 (`bug-fixer`, `business-analyst`,
  `code-quality-reviewer`, `code-security-reviewer`,
  `product-owner`, `project-manager`, `scrum-master`,
  `technical-analyst`, `test-architect`, `ux-designer`).
- **RENAME** — 0 of 14. No subagent's current name
  *outright violates* a documented rule that does not
  also have a counter-rule from another supported
  provider. The action-orientation question is style,
  not violation; the single-English-word generic-name
  question is collision-risk, not violation.
- **NEEDS-DECISION** — 4 of 14 (`architect`,
  `developer`, `devops`, `tester`). All four are
  single-token role labels where (a) action-oriented
  vs role-oriented and (b) bare-generic vs
  namespace-prefix are the open questions. Logged as
  RDEBT-032 + RDEBT-033.

**Per-provider target install paths** for the 14
subagents (audit row 1, `architect`, as a worked
example; the same shape applies to all 14):

| Provider | Path | Format | Rendering notes |
|---|---|---|---|
| Claude Code | `.claude/agents/architect.md` | Markdown + YAML | Verbatim copy |
| Copilot | `.github/agents/architect.agent.md` | Markdown + YAML | Filename gains `.agent.md`; frontmatter filtered |
| Cursor | `.cursor/agents/architect.md` | Markdown + YAML | Frontmatter filtered; `readonly` MAY be set false |
| OpenCode | `.opencode/agents/architect.md` | Markdown + YAML | Frontmatter MUST add `mode: subagent` |
| Windsurf | `.windsurf/workflows/architect.md` | Markdown (no YAML) | Frontmatter STRIPPED; ≤ 12 000 chars |
| Gemini CLI | `.gemini/agents/architect.md` | Markdown + YAML | Frontmatter filtered to Gemini-supported keys |
| Codex | `.codex/agents/architect.toml` | TOML | Body becomes `developer_instructions` |

Whether the current installer (`installer.py:429-494`)
performs the per-provider rendering above is
**(unverified — confirm)** per RDEBT-027.

The audit table replaces no decisions on the
user's behalf — every NEEDS-DECISION row is logged
as an RDEBT and waits for the decider listed in
ADR-020 §Status to confirm. KEEP rows still trigger
the description-tightening work in RDEBT-034.

## Traceability

- **ADRs**: ADR-003 (offline), ADR-004 (manifests),
  ADR-005 (output formats), ADR-009 (static registry),
  ADR-011 (`.kiss/context.yml`), ADR-012 (two-mode UX),
  ADR-018 (narrow integration scope to seven AIs),
  ADR-019 (sibling: agent-skill naming + structure),
  ADR-020 (subagent naming + structure — this spec's
  rule source).
- **Source modules**:
  `src/kiss_cli/installer.py:429-494`
  (`install_custom_agents`);
  `src/kiss_cli/integrations/base.py:56-1374` (per-AI
  format families);
  `src/kiss_cli/integrations/manifest.py:50-265`.
- **Tests**: `tests/test_init_multi.py`,
  `tests/test_offline.py`. New parity / format tests are
  TDEBT (see RDEBT-027).
- **Bundled assets**: 14 role-agent prompts under
  `subagents/`.
- **Research**: `docs/research/ai-providers-2026-04-26.md`,
  `docs/AI-urls.md`.
- **Related specs**: `agent-skills-system/spec.md` (skills
  side; complementary, no FR overlap),
  `integration-system/spec.md` (the supported-AI list and
  per-AI format families), `kiss-init/spec.md` (the
  install flow), `kiss-upgrade/spec.md` (the refresh
  flow), `build-and-distribution/spec.md`.
- **Related debts**: RDEBT-024 (resolved — source narrowed to
  7 AIs), RDEBT-025 (per-AI subagent format
  unverified — Windsurf workflows ≈ subagents),
  RDEBT-026 (per-AI agent-file `CLAUDE.md` /
  `AGENTS.md` / `GEMINI.md` layout unverified against
  installer), RDEBT-027 (per-AI subagent install
  target / format unverified against installer source —
  supersedes older RDEBT-020), RDEBT-028 (two-mode UX
  clause + AI-only scope coverage in role-agent prompts
  unverified); RDEBT-032 (subagent naming style:
  role-oriented vs action-oriented — ADR-020),
  RDEBT-033 (subagent `kiss-` prefix + built-in
  collision risk — ADR-020), RDEBT-034 (description
  tightening pass for 14 prompts — ADR-020),
  RDEBT-035 (spec/code divergence: subagent renames +
  per-AI rendering proposed in specs only — ADR-020);
  cross-link TDEBT-028 (resolved — source narrowed to 7
  AIs), TDEBT-030 (source-side rename +
  per-AI rendering pass for ADR-020).
