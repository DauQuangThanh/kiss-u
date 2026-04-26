# ADR-018: Narrow integration scope to seven supported AIs

**Date:** 2026-04-26
**Status:** Accepted
**Decider:** (decider: TBD — confirm)

## Context

KISS started by registering 13 AI-provider integrations
inline in `_register_builtins()`
(`src/kiss_cli/integrations/__init__.py:14-84`). Many of those
integrations do not have official agent-skills-style or
subagent-style documentation that KISS can target reliably,
and several have small or unverified user bases. Maintaining
all 13 stretches the supported surface (per-AI install layout,
manifest format, agent-file convention) without proportional
user value.

On 2026-04-26 the user provided
`docs/AI-urls.md` as the authoritative source of truth for
which AIs KISS supports. That file lists exactly **seven**
providers (each with a documented agent-skills page and a
documented subagent / custom-agent / workflow page) plus the
agentskills.io specification:

1. **Claude Code** — `code.claude.com/docs/en/sub-agents`,
   `platform.claude.com/docs/en/agents-and-tools/agent-skills/
   overview`,
   `platform.claude.com/docs/en/agents-and-tools/agent-skills/
   best-practices`. Agent file: `<root>/CLAUDE.md`.
2. **GitHub Copilot** —
   `docs.github.com/en/copilot/concepts/agents/about-agent-skills`,
   `code.visualstudio.com/docs/copilot/customization/subagents`
   (subagents ≈ subagents). Agent file: `<root>/AGENTS.md`.
3. **Cursor Agent** — `cursor.com/docs/skills`,
   `cursor.com/docs/subagents`. Agent file: `<root>/AGENTS.md`.
4. **OpenCode** — `opencode.ai/docs/agents/`,
   `opencode.ai/docs/skills/`. Agent file: `<root>/AGENTS.md`.
5. **Windsurf** —
   `docs.windsurf.com/windsurf/cascade/skills`,
   `docs.windsurf.com/windsurf/cascade/workflows` (workflows
   ≈ subagents). Agent file: `<root>/AGENTS.md`.
6. **Gemini CLI** — `geminicli.com/docs/cli/skills/`,
   `geminicli.com/docs/core/subagents/`. Agent file:
   `<root>/GEMINI.md`.
7. **Codex** — `developers.openai.com/codex/skills`,
   `developers.openai.com/codex/subagents`. Agent file:
   `<root>/AGENTS.md`.

Plus the general agent-skills standard at
`agentskills.io/specification`.

The integrations currently in code but not on the supported
list:

- `kiro_cli` (Kiro CLI),
- `auggie` (Auggie),
- `tabnine` (Tabnine),
- `kilocode` (Kilocode),
- `agy` (Antigravity),
- `generic` (Generic / BYO).

## Decision

KISS supports **exactly the seven AI providers** listed in
`docs/AI-urls.md`:
`claude`, `copilot`, `cursor_agent`, `opencode`, `windsurf`,
`gemini`, `codex`. Adding any other provider — or
reintroducing one of the six removed providers — requires a
superseding ADR.

The source-code change to `_register_builtins()` and to
`integrations/catalog.json`, and the corresponding test cleanup
in `tests/test_init_multi.py`, are deferred to a future
source-code pass; this ADR records the scope decision only.
The spec / code divergence is tracked as **TDEBT-028**
(architecture) and **RDEBT-024** (spec).

This ADR is `Accepted`. The source-code narrowing pass was
completed on 2026-04-26.

## Consequences

- (+) Smaller maintenance surface — seven providers instead of
  13 means seven sets of folder conventions, manifest formats,
  and per-AI tests.
- (+) Each supported provider has at least one official
  documentation page for both skills and subagents (per
  `docs/AI-urls.md`); KISS can rely on those pages as the
  source of truth for install layout. The unsupported six
  often lack such pages, leading to guess-work and drift.
- (+) The decision is recorded with concrete URLs per AI, so a
  future contributor can re-derive the per-AI install layout
  from those pages alone.
- (−) ~~Until the source-code narrowing pass lands, the spec
  declares seven supported AIs while the code still ships 13.~~
  Resolved 2026-04-26: the source-code narrowing is complete.
  Users running `kiss init --integration generic` (or any of
  the other five removed keys) now see "Unknown integration".
- (−) Existing users of the six removed integrations who
  upgrade kiss will see "Unknown integration: '<key>'" on
  subsequent `kiss integration install` calls.
- (−) The "bring your own AI" escape hatch (`generic`) is
  removed; users on unsupported AIs must either wait for an
  upstream addition or fork. ADR-009 already noted this is
  the trade-off for the static-registry model.

## Alternatives considered

- **Keep all 13** — rejected: the maintenance surface is
  disproportionate to user value, and several of the six
  removed providers have no official agent-skills /
  subagent documentation that KISS can target.
- **Soft-deprecate (mark unsupported but keep in code)** —
  rejected: users would still see the integrations in
  `kiss integration list`, leading to confusion. A hard cut
  is clearer once the source-code pass runs.
- **Plugin discovery** — rejected by ADR-009; reintroducing
  it just to host the six removed providers as community
  plugins would break the offline-after-install invariant
  and the asset-integrity invariant.

## Source evidence

- `docs/AI-urls.md` (authoritative supported-AI list,
  provided by user 2026-04-26).
- `docs/research/ai-providers-2026-04-26.md` (per-AI format
  facts, derived via WebFetch from the URLs above).
- `docs/specs/integration-system/spec.md` FR-016 / FR-017
  (spec encoding of this decision).
- `src/kiss_cli/integrations/__init__.py:14-84` (registry
  — 7 entries after narrowing).
- `integrations/catalog.json` (catalog metadata — 7
  entries after narrowing).
- ADR-009 (static integration registry — supersedes nothing
  but anchors the no-plugin policy this ADR depends on).

## Cross-references

- **RDEBT-024** — resolved; source narrowed to 7 AIs on
  2026-04-26.
- **TDEBT-028** — resolved; source narrowed to 7 AIs on
  2026-04-26.
- **RDEBT-025** — Windsurf workflows ≈ subagents
  approximation needs user confirmation.
- **RDEBT-026** — per-AI agent-file (`CLAUDE.md` /
  `AGENTS.md` / `GEMINI.md`) layout unverified against
  installer behaviour.
- **RDEBT-027** — per-AI subagent install target / format
  unverified against installer source (supersedes
  RDEBT-020 for the seven supported AIs).
