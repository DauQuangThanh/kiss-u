# ADR-019: Agent-skill naming and structure aligned to provider best practices

**Date:** 2026-04-26
**Status:** Proposed
**Decider:** (decider: TBD — confirm)

## Context

KISS ships ≈ 49 agent-skill bundles under `agent-skills/kiss-*/`
plus 5 non-`kiss-` bundles (`simplify`, `claude-api`, `init`,
`review`, `security-review`). Per CLAUDE.md "Agent-skills
standard", every bundle is supposed to conform to the
[agentskills.io specification](https://agentskills.io/specification)
and to whatever each of the seven supported AI providers (per
ADR-018) layers on top.

The seven supported providers each publish naming / structure
guidance; the universally-shared and the provider-specific
rules were collected in `docs/research/ai-providers-2026-04-26.md`
and re-confirmed via WebFetch on 2026-04-26 of:

- `agentskills.io/specification`
- `platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices`
- `platform.claude.com/docs/en/agents-and-tools/agent-skills/overview`
- `docs.github.com/en/copilot/concepts/agents/about-agent-skills`
- `cursor.com/docs/skills`
- `opencode.ai/docs/skills/`
- `docs.windsurf.com/windsurf/cascade/skills`
- `geminicli.com/docs/cli/skills/`
- `developers.openai.com/codex/skills`

### Universally-shared rules (cited by ≥ 3 providers)

1. **Folder name = `name:` frontmatter** — agentskills.io
   ("Must match the parent directory name"), Cursor ("Must
   match the parent folder name"), OpenCode (regex + "must
   match the directory name housing the SKILL.md"),
   Claude Code overview.
2. **`name`: 1–64 chars; `[a-z0-9]` and `-` only; no
   leading / trailing / consecutive hyphens** — agentskills.io,
   Claude Code, OpenCode (`^[a-z0-9]+(-[a-z0-9]+)*$`).
3. **`description`: 1–1024 chars, non-empty, says what the
   skill does AND when to invoke it** — agentskills.io,
   Claude Code, Cursor, Windsurf.
4. **`description` written in third person** — Claude Code
   best-practices ("Always write in third person … the
   description is injected into the system prompt").
5. **Single-purpose per skill** — Codex ("Keep each skill
   focused on one job"); Claude Code best-practices ("Avoid
   vague names: `helper`, `utils`, `tools`") implies the
   same; Cursor "keep your main `SKILL.md` focused".
6. **Reserved words** — Claude Code best-practices forbids
   `anthropic` and `claude` in the `name` field.
7. **Bundle layout: `<skill>/SKILL.md` required; optional
   `scripts/`, `references/`, `assets/`** — agentskills.io.
8. **No prefix / namespace requirement** — none of the seven
   providers prescribe a `kiss-` (or any other) prefix; the
   spec is namespace-agnostic. OpenCode mentions prefix
   patterns only for permission allow-lists, not naming.
9. **Naming style** — Claude Code best-practices recommends
   **gerund form** (verb + -ing, e.g. `processing-pdfs`) but
   accepts noun-phrase (`pdf-processing`) and action-oriented
   (`process-pdfs`) alternatives. Other providers don't
   prescribe a style.

### Provider-specific divergences

- **Codex** — accepts no max-length but has a metadata cap
  ≈ 2 % of context (≈ 8 000 chars). "Front-load the key use
  case and trigger words so Codex can still match the skill
  if descriptions are shortened."
- **Windsurf** — workflows (≈ subagents) cap at 12 000 chars;
  no skills-side max length documented.
- **Gemini CLI** and **Copilot** — neither documents a
  name-length or description-length cap; both inherit
  agentskills.io defaults.

### Current state

The 49 `kiss-*` skills universally use `kiss-<verb-or-noun>` —
a `kiss-` prefix followed by an action / noun phrase. The
prefix is not required by any provider but is also not
forbidden, and it acts as a workspace namespace.

The 5 non-`kiss-` skills (`simplify`, `claude-api`, `init`,
`review`, `security-review`) break the namespace; one of
them — **`claude-api`** — uses the literal reserved word
`claude` as the leading token, which violates the Claude Code
best-practices ban on reserved words in `name:` (the rule
forbids `anthropic` and `claude`). At least the bare `init`
risks colliding with Claude Code's built-in `/init` slash
command; bare `review` and bare `security-review` are
generic names of the type Claude Code best-practices flag
("Avoid vague names: `helper`, `utils`, `tools`").

A handful of `kiss-*` names are pairs that may overlap and
risk Claude picking the wrong one at activation time
(`kiss-change-register` vs `kiss-change-control`,
`kiss-quality-review` vs `kiss-quality-gates`,
`kiss-test-cases` vs `kiss-test-execution`).

## Decision

Adopt the following naming-and-structure rules for every
skill bundle that ships in `agent-skills/`:

1. **Folder name = `name:` frontmatter** (agentskills.io
   universal).
2. **`name` validates against** `^[a-z0-9]+(-[a-z0-9]+)*$`,
   length ≤ 64.
3. **`name` MUST NOT contain** `anthropic` or `claude` as a
   token (Claude Code reserved-words ban).
4. **`description` is** 1–1024 chars, third-person, single
   sentence ideally, says what AND when to use, front-loads
   the trigger keywords (Codex shortens descriptions first).
5. **Each skill is single-purpose** — if the description
   needs the word "and" between two distinct actions, the
   skill MUST be split.
6. **No bare-generic names** — `helper`, `utils`, `tools`,
   `init`, `review` are banned at the top level; use a
   qualifier (`kiss-init`, `kiss-quality-review`).
7. **Bundle layout**:
   `<skill>/SKILL.md` (required) +
   optional `scripts/` (executable code) +
   optional `references/` (additional docs, loaded on
   demand) +
   optional `assets/` (templates, images, data) +
   optional `templates/` (KISS-specific synonym for the
   agentskills.io `assets/templates/` slot — kept because
   the existing per-skill bundle already uses it).
8. **Naming style preference** — verb-then-noun
   (action-oriented, e.g. `kiss-clarify-specs`,
   `kiss-codebase-scan`). Gerund form is accepted but not
   required — KISS is namespace-prefixed already, which
   makes the gerund form redundant in many cases. Gerund
   alternatives are recorded in the audit table where they
   read more naturally.
9. **`kiss-` prefix policy** — KEEP, as a namespace marker
   that disambiguates installer-managed bundles from
   user-authored bundles in the same `.<provider>/skills/`
   folder. The prefix is NOT required by any provider but
   is also NOT forbidden, and it makes uninstall and
   upgrade safer (only `kiss-*` folders are managed by the
   installer's manifest).

The renames adopted by this ADR are listed by RULE, not by
individual skill — the per-skill audit (CURRENT → PROPOSED
or KEEP) lives in the **Naming Audit Appendix** of
`docs/specs/agent-skills-system/spec.md` so the audit
table can grow without re-opening this ADR.

## Consequences

**Positive:**

- Every supported AI's discovery / activation logic ranks
  KISS skills correctly — the `description` follows
  Claude Code's third-person + what-and-when rule, which
  is the strictest of the seven providers.
- The `kiss-` namespace makes uninstall / upgrade safer
  (the manifest filters by prefix; user-authored skills
  in the same directory are untouched).
- The reserved-word ban removes the `claude-api` collision
  with Claude Code's name-validation rule. Renaming the
  bare `init` / `review` / `security-review` skills
  removes the collision with Claude Code's built-in
  `/init`, `/review`, `/security-review` slash commands.
- Single-purpose enforcement removes the
  `kiss-change-register` / `kiss-change-control` ambiguity.

**Negative / costs:**

- **Spec-vs-code divergence** — the audit table proposes
  renames for several `kiss-*` and non-`kiss-` skills, but
  the actual folder names on disk in `agent-skills/`
  remain unchanged. The source-code rename pass is
  deferred to a separate ADR + PR per **CLAUDE.md**'s
  "Never rename in source code … this pass is specs-only"
  ground rule. Logged as **TDEBT** in
  `docs/architecture/tech-debts.md` and as **RDEBT** in
  `docs/specs/requirement-debts.md`.
- **Migration cost** — when the source rename pass runs,
  every `agents.py` registry line, every `skill_assets.py`
  reference, every `tests/test_agent_skills_compliance.py`
  fixture, and every cross-spec reference will need to
  flip in lock-step. The audit table footnotes
  ("formerly `kiss-foo`") are the migration trail.
- **Discoverability win** — once renames land,
  Claude Code (the strictest provider on naming) will
  rank KISS skills more reliably; the un-prefixed
  `simplify` / `review` / etc. will no longer compete
  with provider-built-in commands.

## Alternatives considered

- **Drop the `kiss-` prefix entirely** — rejected. The
  prefix has a real role (uninstall safety + installer
  manifest filter), and no provider forbids it. Removing
  it would force the installer to track per-skill
  ownership in a sidecar file.
- **Force gerund form (verb-ing) everywhere** — rejected.
  Claude Code best-practices accept verb-then-noun and
  noun-phrase as alternatives. Forcing gerund form
  ("clarifying-specs", "codebase-scanning") would mean
  ≈ 49 renames for marginal benefit.
- **Adopt the reserved-words ban only for Claude Code
  installs** — rejected. Per-provider naming would
  require provider-specific rendering of the `name:`
  field, which contradicts the "single source per skill,
  installer renders to per-AI tree" design (FR-002 in
  `agent-skills-system/spec.md`).

## Traceability

- **Best-practice URLs:** `agentskills.io/specification`;
  `platform.claude.com/docs/en/agents-and-tools/
  agent-skills/best-practices`;
  `platform.claude.com/docs/en/agents-and-tools/
  agent-skills/overview`;
  `docs.github.com/en/copilot/concepts/agents/about-
  agent-skills`;
  `cursor.com/docs/skills`;
  `opencode.ai/docs/skills/`;
  `docs.windsurf.com/windsurf/cascade/skills`;
  `geminicli.com/docs/cli/skills/`;
  `developers.openai.com/codex/skills`.
- **Specs:** `docs/specs/agent-skills-system/spec.md`
  (Functional Requirements, Key Entities, Naming Audit
  Appendix), `docs/specs/subagent-system/spec.md` (cross-
  reference for renamed skills mentioned by the brief).
- **Research:** `docs/research/ai-providers-2026-04-26.md`.
- **Cross-link ADRs:** ADR-018 (seven-AI scope —
  prerequisite); ADR-005 (three output formats — the
  rendered `name:` field is what each integration's
  format writer emits); ADR-009 (static integration
  registry — where the per-AI skill folder convention
  lives).
- **Related debts:** RDEBT-029 … RDEBT-031 (audit
  NEEDS-DECISION items, spec/code divergence,
  cross-provider rule conflicts) in
  `docs/specs/requirement-debts.md`; TDEBT-029 (source-
  side rename pass) in `docs/architecture/tech-debts.md`.

**Status: Proposed** — flips to `Accepted` once the decider
listed at the top approves the rules; the per-skill audit
remains in `agent-skills-system/spec.md` and may be edited
without re-opening this ADR.
