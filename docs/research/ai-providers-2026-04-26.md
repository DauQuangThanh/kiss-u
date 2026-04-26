# AI Providers Research Summary (2026-04-26)

> Compiled by `business-analyst` (auto mode) on 2026-04-26 from
> WebFetch of the URLs listed in `docs/AI-urls.md`. The seven AIs
> below are the **only** integrations supported going forward.
>
> Concrete facts (file extension, manifest fields, install paths)
> are sourced directly from each provider's documentation. Items
> the docs do not pin are marked `(unverified — confirm)` and
> tracked as RDEBTs in `docs/specs/requirement-debts.md`.

## Scope and method

- **Source list:** `docs/AI-urls.md` — 16 URLs covering the
  agent-skills format, plus per-provider skill / subagent docs.
- **Out of scope (removed from spec):** `kiro-cli`, `auggie`,
  `tabnine`, `kilocode`, `agy` (Antigravity), `generic`. These
  remain in the source code (`src/kiss_cli/integrations/`) and
  the catalog JSON; the source-code narrowing is a separate
  pass.
- **General agent-skills standard:** every supported AI conforms
  (with provider-specific deviations) to the
  [agentskills.io specification](https://agentskills.io/specification).

## Agent-skills baseline (agentskills.io)

- **Bundle layout:** `<skill-name>/SKILL.md` + optional
  `scripts/`, `references/`, `assets/` subdirectories.
- **`SKILL.md` format:** YAML frontmatter + Markdown body.
- **Required frontmatter:**
  - `name` — 1-64 chars, lowercase `a-z` + digits + hyphens, no
    leading / trailing / consecutive hyphens, MUST match parent
    directory name.
  - `description` — 1-1024 chars, non-empty, says what the skill
    does and when to invoke it.
- **Optional frontmatter:** `license`, `compatibility` (≤ 500
  chars), `metadata` (string-to-string map), `allowed-tools`
  (experimental, space-separated).
- **Progressive disclosure:** metadata always loaded (~100 tok);
  body loaded on activation (< 5 000 tok recommended); resources
  loaded on demand.
- **Validator:** `skills-ref validate ./my-skill` (open-source).

## Per-AI summary

| # | Integration ID | Display name | Agent file | Skills format | Subagent / equivalent format | Notes |
|---|----------------|--------------|------------|---------------|------------------------------|-------|
| 1 | `claude` | Claude Code | `<root>/CLAUDE.md` | agentskills.io `SKILL.md` folder; project `.claude/skills/<name>/SKILL.md`, user `~/.claude/skills/<name>/SKILL.md` | Subagent files `.md` under `.claude/agents/` (project) or `~/.claude/agents/` (user); YAML frontmatter (`name`, `description`, optional `tools`, `model`); body becomes the system prompt | Anthropic `code.claude.com/docs/en/sub-agents`, `platform.claude.com/docs/en/agents-and-tools/agent-skills/overview` |
| 2 | `copilot` | GitHub Copilot | `<root>/AGENTS.md` | agentskills.io `SKILL.md`; project `.github/skills/`, `.claude/skills/`, `.agents/skills/`; user `~/.copilot/skills/`, `~/.claude/skills/`, `~/.agents/skills/` | VS Code "custom agents" — file `*.agent.md` under `.github/agents/` or `.claude/agents/`; Markdown + YAML frontmatter (`name`, `description`, `tools`, `model`, `agents`, `handoffs`, `user-invocable`, `disable-model-invocation`, `hooks`) | subagents are the subagent equivalent (default: `(unverified — confirm)`); manifest format spec gaps logged as RDEBT |
| 3 | `cursor_agent` | Cursor Agent | `<root>/AGENTS.md` | agentskills.io `SKILL.md`; project `.agents/skills/`, `.cursor/skills/`; user `~/.agents/skills/`, `~/.cursor/skills/` | Subagent `.md` files under `.cursor/agents/`, `.claude/agents/`, `.codex/agents/` (project) or `~/.cursor/agents/`, `~/.claude/agents/`, `~/.codex/agents/` (user); YAML frontmatter (`name`, `description`, `model`, `readonly`, `is_background`); body is the system prompt | `cursor.com/docs/skills`, `cursor.com/docs/subagents`. `.cursor/` precedence over `.claude/` / `.codex/` |
| 4 | `opencode` | OpenCode | `<root>/AGENTS.md` | agentskills.io `SKILL.md`; project `.opencode/skills/<name>/SKILL.md`, `.claude/skills/<name>/SKILL.md`, `.agents/skills/<name>/SKILL.md`; user `~/.config/opencode/skills/<name>/SKILL.md` | Markdown agents under `.opencode/agents/` (project) or `~/.config/opencode/agents/` (user); frontmatter has `description` (required), `mode` (`primary` / `subagent` / `all`); body is the system prompt | `opencode.ai/docs/agents/`, `opencode.ai/docs/skills/` |
| 5 | `windsurf` | Windsurf (Cascade) | `<root>/AGENTS.md` | `SKILL.md` folder under `.windsurf/skills/<name>/` (workspace), `~/.codeium/windsurf/skills/<name>/` (global); cross-agent fallback to `.agents/skills/`, `.claude/skills/` | **Workflows** approximate the subagent role; `.md` files under `.windsurf/workflows/` (workspace) or `~/.codeium/windsurf/global_workflows/`; max 12 000 chars; manual invocation via `/<workflow-name>` | `docs.windsurf.com/windsurf/cascade/skills`, `docs.windsurf.com/windsurf/cascade/workflows`. Workflows ≠ classic subagents — approximation; logged as RDEBT |
| 6 | `gemini` | Gemini CLI | `<root>/GEMINI.md` | agentskills.io `SKILL.md`; project `.gemini/skills/`, `.agents/skills/`; user `~/.gemini/skills/`, `~/.agents/skills/`; also `.skill` zip distribution | Subagents `.md` under `.gemini/agents/` (project) or `~/.gemini/agents/` (user); YAML frontmatter (`name`, `description`, optional `kind`, `tools`, `mcpServers`, `model`, `temperature`, `max_turns`, `timeout_mins`); body becomes system prompt | `geminicli.com/docs/cli/skills/`, `geminicli.com/docs/core/subagents/` |
| 7 | `codex` | Codex (OpenAI) | `<root>/AGENTS.md` | `SKILL.md` directory; optional `agents/openai.yaml`; skill referenced as `$skill-name`; metadata cap ≈ 2 % of context (≈ 8 000 chars) | Subagents are `.toml` files under `.codex/agents/` (project) or `~/.codex/agents/` (user); required keys: `name`, `description`, `developer_instructions`; optional `nickname_candidates`, `model`, `model_reasoning_effort`, `sandbox_mode`, `mcp_servers`, `skills.config` | `developers.openai.com/codex/skills`, `developers.openai.com/codex/subagents` |

## Common cross-cutting facts

- **All seven** support an agentskills.io-style `SKILL.md`
  bundle with YAML frontmatter (`name`, `description`).
- **Six of seven** use Markdown for subagents; **only Codex**
  uses TOML for subagents.
- **Three distinct agent-file conventions** are needed for the
  installer: `CLAUDE.md`, `AGENTS.md`, `GEMINI.md` — the per-AI
  agent-file column above pins each.
- **Two providers blur the subagent boundary:** Copilot calls
  them "custom agents", Windsurf calls them "workflows"
  (max 12 000 chars). Both are functionally KISS subagents for
  installer purposes; the approximation is logged as RDEBT.

## Removed from scope (2026-04-26)

The integrations below remain in `src/kiss_cli/integrations/`
and `integrations/catalog.json` as of this writing but are
**not** in the supported-provider list:

- `kiro-cli` (Kiro CLI)
- `auggie` (Auggie)
- `tabnine` (Tabnine)
- `kilocode` (Kilocode)
- `agy` (Antigravity)
- `generic` (Generic / BYO)

Per the ground rules of this docs-only pass, no source code or
catalog JSON is changed in this commit; the spec/code
divergence is logged as RDEBT in
`docs/specs/requirement-debts.md` and as TDEBT in
`docs/architecture/tech-debts.md`.

## Sources

- `docs/AI-urls.md` — authoritative URL list (provided by user).
- WebFetch results, 2026-04-26 (cached for 15 min in tool
  storage; not persisted).

## Open questions / unverified items

- Whether Copilot subagents are the canonical subagent
  surface or whether GitHub also exposes a separate
  agent-skills-style subagent format
  `(unverified — confirm)`.
- Whether Windsurf's "workflow" = subagent semantically (input
  contract, output contract, error propagation)
  `(unverified — confirm)` — it is the closest analogue and is
  used as the mapping in the spec.
- Whether the per-AI agent-file (`CLAUDE.md` / `AGENTS.md` /
  `GEMINI.md`) installation actually matches what the kiss
  installer writes today `(unverified — confirm)` — code-side
  audit deferred.
