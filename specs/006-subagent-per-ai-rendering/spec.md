# Feature Specification: subagent-per-ai-rendering

**Feature Slug**: `subagent-per-ai-rendering`
**Created**: 2026-04-26
**Status**: Draft
**Branch**: `006-subagent-per-ai-rendering`

## Problem Statement

The `install_custom_agents()` function copies 14 subagent prompts
from `subagents/` into each integration's agent directory. The
source files are authored in Claude Code format (Markdown with
YAML frontmatter: `name`, `description`, `tools`, `model`,
`color`). However, each of the 7 supported AIs expects different:

- **Target directories** — most use `./<provider>/agents/` but
  Codex currently writes to `.agents/agents/` (double nesting)
  and Windsurf uses workflows, not agents.
- **File extensions** — Copilot needs `.agent.md` (already
  handled); Codex may need `.toml`.
- **Frontmatter fields** — OpenCode needs `mode: subagent`;
  Gemini needs `kind: subagent`; Codex needs
  `developer_instructions` (TOML key).
- **Content limits** — Windsurf workflows have a 12,000 char
  ceiling.

Currently only Copilot has overrides (`custom_agent_filename` and
`transform_custom_agent_content`). The other 6 integrations use
the base class identity methods, meaning they install Claude-
format prompts verbatim.

## Per-AI Requirements (from `docs/AI-urls.md` research)

| AI | Agent dir | File ext | Required frontmatter | Content limits |
|----|-----------|----------|---------------------|----------------|
| Claude | `.claude/agents/` | `.md` | `name`, `description` (opt: `tools`, `model`) | None |
| Copilot | `.github/agents/` | `.agent.md` | `name`, `description` (opt: `tools`, `model`) | None |
| Cursor | `.cursor/agents/` | `.md` | `name`, `description` (opt: `model`) | None |
| OpenCode | `.opencode/agents/` | `.md` | `description`, `mode: subagent` required | None |
| Windsurf | `.windsurf/workflows/` | `.md` | None (plain Markdown) | 12,000 chars |
| Gemini | `.gemini/agents/` | `.md` | `name`, `description` (opt: `kind`, `tools`, `model`) | None |
| Codex | `.codex/agents/` | `.md` | `name`, `description`, `developer_instructions` | ~8,000 chars |

## User Stories

### US-1: Fix Codex agent directory (Priority: P1)

Codex currently writes to `.agents/agents/` (folder=`.agents/`,
agents\_subdir=`agents`). It should write to `.codex/agents/`.

**Acceptance**: After `kiss init --integration codex`, subagents
are in `.codex/agents/`, not `.agents/agents/`.

### US-2: Add OpenCode `mode: subagent` frontmatter (Priority: P1)

OpenCode requires `mode: subagent` in the frontmatter for the
agent to surface as a subagent instead of a primary agent.

**Acceptance**: Installed OpenCode subagent files contain
`mode: subagent` in their frontmatter.

### US-3: Add Gemini `kind: subagent` frontmatter (Priority: P2)

Gemini CLI uses `kind: subagent` to differentiate subagents from
primary agents.

**Acceptance**: Installed Gemini subagent files contain
`kind: subagent` in their frontmatter.

### US-4: Windsurf workflow adaptation (Priority: P2)

Windsurf installs subagents as workflows under
`.windsurf/workflows/`. The `agents_subdir` should be
`workflows` and the 12,000 char limit should be documented.

**Acceptance**: Subagents install to `.windsurf/workflows/` and
the installer warns if any prompt exceeds 12,000 chars.

### US-5: Codex frontmatter adaptation (Priority: P2)

Codex uses `developer_instructions` as the body key. The
`transform_custom_agent_content` should rewrite the frontmatter
accordingly.

**Acceptance**: Installed Codex subagent files have the
`developer_instructions` field populated from the prompt body.

### US-6: Strip unsupported frontmatter fields (Priority: P3)

Fields like `color` and `tools` may not be recognized by all AIs.
Each integration should strip fields it doesn't support.

**Acceptance**: Cursor subagents don't have `color` or `tools`
fields. Windsurf workflows don't have YAML frontmatter at all.

## Functional Requirements

- **FR-001**: Codex config MUST set `folder` to `.codex/`.
- **FR-002**: Windsurf config MUST set `agents_subdir` to
  `workflows`.
- **FR-003**: OpenCode MUST override
  `transform_custom_agent_content` to inject `mode: subagent`
  into frontmatter.
- **FR-004**: Gemini MUST override
  `transform_custom_agent_content` to inject `kind: subagent`
  into frontmatter.
- **FR-005**: Codex MUST override
  `transform_custom_agent_content` to add
  `developer_instructions` from the body.
- **FR-006**: Windsurf MUST override
  `transform_custom_agent_content` to strip frontmatter and
  produce plain Markdown workflows.
- **FR-007**: The installer SHOULD warn when a prompt exceeds
  12,000 chars (Windsurf limit).
- **FR-008**: Cursor MUST override
  `transform_custom_agent_content` to strip `color` and `tools`.

## Success Criteria

- **SC-001**: `kiss init --integration <key>` produces correctly-
  formatted subagent files for all 7 AIs.
- **SC-002**: All existing tests pass.
- **SC-003**: New per-AI tests verify frontmatter transformation.

## Traceability

- **Resolves**: RDEBT-025, RDEBT-026, RDEBT-027, RDEBT-028,
  RDEBT-035
