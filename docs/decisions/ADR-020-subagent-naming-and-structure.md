# ADR-020: Subagent naming and structure aligned to provider best practices

**Date:** 2026-04-26
**Status:** Proposed
**Decider:** (decider: TBD — confirm)

## Context

KISS ships 14 role-agent prompts under `subagents/<role>.md`
(`architect`, `bug-fixer`, `business-analyst`,
`code-quality-reviewer`, `code-security-reviewer`, `developer`,
`devops`, `product-owner`, `project-manager`, `scrum-master`,
`technical-analyst`, `test-architect`, `tester`, `ux-designer`).
These are the **subagents** every supported AI provider exposes,
not agent-skills (covered separately by ADR-019). Each provider
calls the surface a slightly different thing:

- **Claude Code** — *subagents* (`.claude/agents/<name>.md`).
- **GitHub Copilot** — *custom agents*
  (`.github/agents/<name>.agent.md`).
- **Cursor Agent** — *subagents* (`.cursor/agents/<name>.md`).
- **OpenCode** — *agents* with `mode: subagent`
  (`.opencode/agents/<name>.md`).
- **Windsurf** — *workflows* (`.windsurf/workflows/<name>.md`,
  ≤ 12 000 chars, manual `/<name>` invocation).
- **Gemini CLI** — *subagents* (`.gemini/agents/<name>.md`).
- **Codex** — *subagents* (`.codex/agents/<name>.toml`).

Per ADR-018 (the seven-AI scope), KISS only targets these
seven providers; the older `kiro-cli`, `auggie`, `tabnine`,
`kilocode`, `agy`, `generic` integrations are out of scope.

The naming + structure rules each provider publishes were
re-confirmed via WebFetch on 2026-04-26 of:

- `code.claude.com/docs/en/sub-agents`
- `code.visualstudio.com/docs/copilot/customization/subagents`
- `cursor.com/docs/subagents`
- `opencode.ai/docs/agents/`
- `docs.windsurf.com/windsurf/cascade/workflows`
- `geminicli.com/docs/core/subagents/`
- `developers.openai.com/codex/subagents`

### Universally-shared rules (cited by ≥ 3 providers)

1. **Lowercase letters + hyphens (kebab-case)** — Claude Code
   ("Unique identifier using lowercase letters and hyphens"),
   Cursor ("Use lowercase letters and hyphens"), Gemini CLI
   ("Only lowercase letters, numbers, hyphens, and
   underscores"). Windsurf workflow examples use lowercase +
   hyphens (e.g. `/address-pr-comments`). OpenCode does not
   pin characters but examples use kebab-case.
2. **Filename = `name:` frontmatter** — Claude Code, Cursor,
   Gemini CLI, OpenCode all derive the agent identifier
   from the filename when `name:` is omitted; Copilot
   docs explicitly: "If no `name` field exists … the file
   name is used". Codex says "Matching the agent's `name`
   field is conventional but not mandatory; the `name`
   field is authoritative" — the only provider where the
   filename and `name` may legitimately diverge.
3. **`description` is the trigger** — Claude Code ("Claude
   uses each subagent's description to decide when to
   delegate"), Cursor ("Shown in Task tool hints; guides
   Agent delegation decisions … invest heavily in
   description quality"), Gemini CLI ("visible to the main
   agent to help it decide when to call"), OpenCode
   (`description` is the **only** required field), Codex
   (`description` is one of three required fields).
4. **Single-purpose / focused agents** — Claude Code
   ("Design focused subagents: each subagent should excel
   at one specific task"), Cursor ("Write focused agents
   with single, clear responsibilities"), Codex ("The
   best custom agents are narrow and opinionated. Keep
   instructions from drifting into adjacent
   responsibilities"), Gemini CLI ("Tool restriction:
   explicitly grant only necessary tools").
5. **Avoid vague / generic names** — Cursor ("Avoid vague
   descriptions like 'helps with general tasks'"); Claude
   Code best-practices flag generic names of the type
   `helper`, `utils`, `tools`. By extension, generic
   role-only labels with no scope cue are weaker than
   names with a discriminator.
6. **Markdown + YAML frontmatter** is the universal file
   format — every provider except Codex (TOML) and
   Windsurf (Markdown without YAML frontmatter); the
   six Markdown providers all accept the same
   `name` / `description` pair.

### Provider-specific divergences (rules to RESPECT, not pick a winner)

- **Codex naming character set is wider** — Codex allows
  ASCII letters, digits, spaces, hyphens, **and underscores**
  in `name`; reserves the names `default`, `worker`,
  `explorer` (custom agents with matching names take
  precedence but the collision is undesirable).
- **Codex file format is TOML, not Markdown** — required
  TOML keys: `name`, `description`, `developer_instructions`.
  The Markdown body of the bundled `<role>.md` becomes the
  `developer_instructions` value when the installer renders
  to TOML.
- **Copilot file extension is `.agent.md`**, not `.md`.
  Frontmatter accepts `name`, `description`, `tools`,
  `model`, `agents`, `handoffs`, `user-invocable`,
  `disable-model-invocation`, `hooks`. None are formally
  required (all default).
- **Windsurf workflows have no documented YAML frontmatter
  schema** — they are plain Markdown with a title +
  description + numbered steps, capped at 12 000 chars,
  invoked manually via `/<name>`. The 14 role prompts in
  `subagents/` average ≈ 5 000–9 000 chars (within the
  cap) but a few approach the limit.
- **Cursor adds `readonly` and `is_background`
  frontmatter fields** — useful for `code-quality-reviewer`
  / `code-security-reviewer` (read-only), and for
  long-running prompts (`is_background: true`).
- **Gemini CLI allows underscores** in name and adds
  `mcpServers`, `temperature`, `max_turns`, `timeout_mins`
  optional fields.
- **OpenCode uses `mode: subagent`** to mark the surface;
  without the field the agent is treated as `all`
  (primary + subagent). KISS subagents MUST declare
  `mode: subagent` to avoid them surfacing as the main
  conversation.

### Naming style — role-oriented vs action-oriented

The seven providers DISAGREE on naming style:

- **Cursor** prefers **role-oriented** (`debugger`,
  `verifier`, `security-auditor`).
- **OpenCode** prefers **action-oriented** (`code-reviewer`,
  `security-auditor`, `docs-writer`).
- **Codex** prefers **action-oriented** (`pr_explorer`,
  `docs_researcher`, `code_mapper`, `browser_debugger`).
- **Claude Code** examples are mixed (`code-reviewer`,
  `debugger`, `data-scientist`, `db-reader`,
  `browser-tester`).
- **Copilot** examples are mostly role-oriented (`Plan`,
  `Planner`, `Researcher`, `Implementer`).
- **Gemini CLI** examples are mixed (`security-auditor`
  role, `codebase_investigator` action).
- **Windsurf** workflows are action-oriented by the
  surface's design (procedures, not roles).

KISS's 14 names are uniformly **role-oriented** (`architect`,
`developer`, `tester`, …) — the names describe what the
agent **is**, not what it **does**. Forcing every name to
action form (e.g. `develop-features` instead of `developer`)
would be a reasonable choice under OpenCode / Codex
defaults, but contradicts Cursor's documented preference
and is not required by Claude Code (the strictest
character-set provider). The current state is a defensible
trade-off; the question of whether to flip is logged as
**RDEBT-032** for the user to decide.

### Reserved / collision-risk names

- **Claude Code** does NOT publish an agent-side reserved-words
  list (the reserved-words ban applies to skill names per
  ADR-019, not subagent names). However, `developer`,
  `tester`, and `architect` are extremely generic single
  English words that may collide with built-in agents in
  future releases or with user-authored agents in the
  same `.claude/agents/` folder. There is no documented
  collision today, but the risk is documented as
  **RDEBT-033** so the decider can weigh disambiguation.
- **Codex** reserves `default`, `worker`, `explorer` as
  built-in agent names. None of the 14 KISS subagents
  collide.
- **Cursor / Gemini / OpenCode / Copilot / Windsurf** —
  no documented reserved-words lists.

### Current state

- All 14 prompts under `subagents/` use uniform Claude
  Code-style YAML frontmatter (`name`, `description`,
  `tools`, `model`, `color`).
- All 14 names validate against the strictest character
  set (Claude Code's "lowercase letters and hyphens"):
  no underscores, no uppercase, no digits, no leading /
  trailing / consecutive hyphens.
- All 14 `description:` blocks are long paragraphs
  (200–500 words). Per-provider best practices, the
  description is the **trigger** that decides delegation;
  long paragraphs work but are diluted. Claude Code's
  examples for `code-reviewer`, `debugger`, etc. are
  one-to-three sentences, ≈ 30–80 words. Cursor warns
  "vague descriptions like 'helps with general tasks'";
  the current descriptions are not vague but they are
  long and bury the trigger phrase mid-paragraph.
- The `tools:` field uses the Claude Code shape
  (`Read, Write, Edit, Bash, Glob, Grep, [WebFetch,
  WebSearch]`). Other providers either ignore the field
  (Cursor, OpenCode, Codex, Windsurf), accept different
  values (Gemini wildcards `mcp_*`), or use a different
  field name (OpenCode `permission`).
- The `model: inherit` value is universally accepted
  (Cursor docs explicitly: "Model selection (inherit,
  fast, or specific model ID)").
- The `color:` field is Claude Code-specific in the
  agent surface, but OpenCode also accepts a `color`
  frontmatter field.
- A handful of name pairs may overlap and risk a
  delegating model picking the wrong one
  (`tester` vs `test-architect`,
  `code-quality-reviewer` vs `code-security-reviewer`,
  `product-owner` vs `project-manager` vs
  `scrum-master`). Tightened descriptions (rule 3 below)
  resolve this without a rename if the descriptions
  front-load the differentiator.

## Decision

Adopt the following naming-and-structure rules for every
role-agent prompt that ships in `subagents/`:

1. **Filename = `<role>.md` lowercase + hyphens**, length
   ≤ 64 chars. The `name:` frontmatter MUST equal the
   filename without the extension.
2. **`name` validates against** `^[a-z0-9]+(-[a-z0-9]+)*$`
   (kebab-case; the strictest of the seven providers,
   Claude Code). This is a tighter rule than Codex /
   Gemini accept (both allow underscores) but keeping
   one shape across all providers is simpler than
   per-provider rendering and contradicts no rule.
3. **`description` is** 1–3 sentences, third-person,
   front-loads the trigger phrase ("Use proactively
   for …" / "Use when …"), states **what the agent does
   AND when to invoke it**, with the differentiator from
   any sibling agent (e.g. `tester` vs `test-architect`)
   in the first sentence. Hard cap: ≤ 1024 chars
   (the agentskills.io / Claude Code limit), recommended
   length: 200–600 chars. The current 14
   descriptions all exceed the recommended length and
   need tightening; the work is logged as **RDEBT-034**.
4. **Each role-agent is single-purpose** — if the
   description needs the word "and" between two distinct
   responsibilities, the agent SHOULD be re-scoped or
   split. For the existing 14, all roles are coherent
   under their role label; no split is mandated by this
   ADR.
5. **Frontmatter shape (per-provider rendering)** — the
   bundled `<role>.md` carries Claude Code-shaped
   frontmatter (`name`, `description`, `tools`, `model`,
   `color`). The installer renders the per-AI shape on
   install:

   | Provider | File path | Frontmatter / format |
   |---|---|---|
   | Claude Code | `.claude/agents/<role>.md` | YAML: `name`, `description`, `tools`, `model`, `color` (as authored) |
   | Copilot | `.github/agents/<role>.agent.md` | YAML: `name`, `description`, optional `tools`, `model`, `agents`, `handoffs` |
   | Cursor | `.cursor/agents/<role>.md` | YAML: `name`, `description`, optional `model`, `readonly`, `is_background` |
   | OpenCode | `.opencode/agents/<role>.md` | YAML: `description` (required), `mode: subagent`, optional `model`, `permission`, `color` |
   | Windsurf | `.windsurf/workflows/<role>.md` | Plain Markdown, no YAML; ≤ 12 000 chars; first H1 = display name |
   | Gemini CLI | `.gemini/agents/<role>.md` | YAML: `name`, `description`, optional `tools`, `model`, `mcpServers` |
   | Codex | `.codex/agents/<role>.toml` | TOML: `name`, `description`, `developer_instructions` (Markdown body), optional `model`, `model_reasoning_effort`, `sandbox_mode`, `mcp_servers` |

6. **Two-mode UX clause is preserved verbatim** in every
   per-provider rendering, per CLAUDE.md "Every custom
   agent supports two modes" and ADR-012. The installer
   MUST NOT strip the clause when shortening for the
   Windsurf 12 000-char ceiling — if a prompt exceeds
   the Windsurf cap, the installer SHOULD trim
   non-essential examples first; the cap question is
   logged as **RDEBT-025** (existing).
7. **AI-only scope clause is preserved verbatim** in
   every per-provider rendering, per CLAUDE.md "AI-only
   scoping for role skills and custom agents".
8. **Decision-log path is preserved verbatim** —
   `{paths.docs}/agent-decisions/<agent-name>/<YYYY-MM-DD>-decisions.md`
   per CLAUDE.md.
9. **No `kiss-` prefix on subagent names** — unlike
   skills (ADR-019 §9), subagent names are NOT
   namespaced. The reasoning: skills install into
   per-provider skill folders (`.<provider>/skills/`)
   alongside user-authored skills, so the prefix
   protects upgrade / uninstall. Subagents install into
   per-provider agent folders that are conventionally
   project-managed; collision risk with user-authored
   subagents exists but the user already owns the
   namespace. Adding a prefix to all 14 (e.g.
   `kiss-architect`, `kiss-developer`, …) would also
   make the role names more verbose without resolving
   the actual collision risk (which is built-in agents
   per provider, not user agents). Logged as
   **RDEBT-033** for the decider to confirm.
10. **Naming style: role-oriented preferred, action-
    oriented accepted** — KISS's 14 names are
    role-oriented (`architect`, `developer`, …) and
    Cursor / Copilot examples agree. OpenCode and
    Codex prefer action-oriented (`develop-features`,
    `architect-system`). This ADR DOES NOT flip the
    14 names; the trade-off is logged as **RDEBT-032**.
    If the decider accepts action-oriented for the
    next pass, the rename table lives in the
    Naming Audit Appendix of
    `docs/specs/subagent-system/spec.md` and may be
    edited without re-opening this ADR.

The renames adopted by this ADR are listed by RULE, not
by individual subagent — the per-subagent audit
(CURRENT → KEEP / RENAME / NEEDS-DECISION) lives in the
**Naming Audit Appendix** of
`docs/specs/subagent-system/spec.md` so the audit table
can grow without re-opening this ADR.

## Consequences

**Positive:**

- Every supported AI's discovery / activation logic
  ranks KISS subagents correctly — the `description`
  (once tightened per RDEBT-034) follows the
  third-person + what-and-when shape that all seven
  providers depend on for delegation.
- The seven per-AI rendering rules in §5 give the
  installer a single source of truth for what to emit
  in each agent folder; today the rendering is
  **(unverified — confirm)** per RDEBT-027.
- The two-mode UX + AI-only scope + decision-log
  clauses are preserved across all seven providers,
  closing the gap RDEBT-028 raises.
- Cursor's `readonly: true` and `is_background: true`
  hints become available for `code-quality-reviewer`,
  `code-security-reviewer`, and `technical-analyst`
  once the installer supports per-provider
  frontmatter rendering.

**Negative / costs:**

- **Spec-vs-code divergence** — the audit table
  proposes per-subagent verdicts (KEEP / RENAME /
  NEEDS-DECISION) and the rule set above; the actual
  folder + filenames on disk under `subagents/`
  remain unchanged. The source-code rename / installer-
  rendering pass is deferred to a separate ADR + PR
  per CLAUDE.md's "Never rename in source code …
  this pass is specs-only" ground rule. Logged as
  **TDEBT-030** in `docs/architecture/tech-debts.md`
  and as **RDEBT-035** in
  `docs/specs/requirement-debts.md`.
- **Migration cost** — when the source rename / per-
  AI rendering pass runs, the following will need to
  flip in lock-step:
  - `src/kiss_cli/installer.py:429-494`
    (`install_custom_agents`) gains per-provider
    frontmatter rendering branches (Codex TOML,
    Copilot `.agent.md`, Windsurf strip-frontmatter,
    OpenCode `mode: subagent`, Cursor
    `readonly`/`is_background`, Gemini optional
    fields).
  - `src/kiss_cli/integrations/<integration>/__init__.py`
    for all seven providers gains agent-folder + file-
    extension config.
  - `tests/test_init_multi.py` and a new
    `tests/test_subagent_compliance.py` (TDEBT-030)
    enforce the rules per provider.
  - Manifest hashing
    (`src/kiss_cli/integrations/manifest.py`) accounts
    for per-provider rendering being deterministic
    (NFR-006 in `subagent-system/spec.md`).
- **Discoverability win** — once the installer
  renders per-provider frontmatter (`mode: subagent`,
  `readonly`, `is_background`), each AI's delegation
  logic ranks KISS subagents more reliably and respects
  read-only / background hints.
- **Cross-spec sweep needed once `Accepted`** — the
  following spec files reference subagent role names
  and will need a quick read-through to confirm none
  contradict the rules:
  - `docs/specs/subagent-system/spec.md` (already
    updated by this audit)
  - `docs/specs/agent-skills-system/spec.md` (skills
    side; references role names for handoff)
  - `docs/specs/integration-system/spec.md`
    (per-AI agent folder convention)
  - `docs/specs/kiss-init/spec.md` (the install flow)
  - `docs/specs/kiss-upgrade/spec.md` (the refresh
    flow)
  - `docs/specs/kiss-install/spec.md` /
    `docs/specs/kiss-uninstall/spec.md`
  - `docs/specs/build-and-distribution/spec.md`
  - `docs/decisions/ADR-012-two-mode-ux-interactive-and-auto.md`
    (two-mode UX clause source)
  - `docs/decisions/ADR-018-narrow-integration-scope-to-seven-ais.md`
    (the seven-AI list)
  - `docs/decisions/ADR-019-agent-skill-naming-and-structure.md`
    (sibling ADR; cross-link)

## Alternatives considered

- **Mirror ADR-019's `kiss-` prefix policy on
  subagents** — rejected. Subagent folders
  (`.<provider>/agents/`) are project-managed by the
  user; the prefix would make role names more verbose
  without solving the actual collision risk
  (built-in provider agents). Logged as RDEBT-033.
- **Force action-oriented naming for all 14
  (`develop-features`, `design-architecture`, …)** —
  rejected. The current role-oriented names follow
  Cursor's documented preference and Claude Code /
  Copilot examples; flipping would invalidate every
  cross-spec reference and every decision-log path
  (`{paths.docs}/agent-decisions/<agent-name>/`).
  Logged as RDEBT-032.
- **Adopt Cursor's `readonly` and `is_background`
  fields in the bundled `<role>.md` frontmatter** —
  rejected. The bundled prompt is the authoring
  source; per-provider fields belong in the
  installer's rendering branch. Adding Cursor-specific
  keys to every bundled prompt would force
  installer-side filtering for the six other
  providers.
- **Tighten all 14 descriptions in this ADR** —
  rejected. The descriptions are content edits, not
  structural rules; they belong in a separate edit
  pass. Logged as RDEBT-034.
- **Per-provider rendering of `name:`** (drop hyphens
  for Codex, allow underscores for Gemini) — rejected.
  Three output formats are already complex (ADR-005);
  per-provider character-set rendering would force
  every cross-reference (decision-log path,
  `agent-decisions/<agent-name>/` directory, manifest
  hash key) to be provider-aware. The strictest-
  common-subset rule (kebab-case) lets a single name
  flow through all seven renderers.

## Traceability

- **Best-practice URLs:**
  `code.claude.com/docs/en/sub-agents`;
  `code.visualstudio.com/docs/copilot/customization/subagents`;
  `cursor.com/docs/subagents`;
  `opencode.ai/docs/agents/`;
  `docs.windsurf.com/windsurf/cascade/workflows`;
  `geminicli.com/docs/core/subagents/`;
  `developers.openai.com/codex/subagents`.
- **Specs:** `docs/specs/subagent-system/spec.md`
  (Functional Requirements, Key Entities, Naming
  Audit Appendix); `docs/specs/agent-skills-system/spec.md`
  (sibling skill side; references role names but
  does NOT propagate any subagent rename until this
  ADR is `Accepted`).
- **Research:** `docs/research/ai-providers-2026-04-26.md`.
- **Cross-link ADRs:**
  ADR-018 (seven-AI scope — prerequisite);
  ADR-019 (sibling: agent-skill naming + structure
  — same shape applied to skills);
  ADR-012 (two-mode UX — clause preserved by §6);
  ADR-005 (three output formats — the per-provider
  renderer in §5 is the subagent-side mirror);
  ADR-011 (`.kiss/context.yml` —
  `paths.docs` + `agent-decisions/` path).
- **Related debts:**
  RDEBT-025 (Windsurf 12 000-char workflow cap,
  existing),
  RDEBT-027 (per-AI subagent install target /
  format unverified against installer source —
  existing),
  RDEBT-028 (two-mode UX + AI-only scope coverage
  in role-agent prompts unverified — existing),
  RDEBT-032 (role-oriented vs action-oriented naming
  — new),
  RDEBT-033 (`kiss-` prefix on subagents +
  built-in agent collision risk — new),
  RDEBT-034 (description tightening pass — new),
  RDEBT-035 (spec/code divergence: subagent
  renames + per-AI rendering proposed in specs only
  — new),
  TDEBT-030 (source-side rename + per-AI rendering
  pass — new) in
  `docs/architecture/tech-debts.md`.

**Status: Proposed** — flips to `Accepted` once the
decider listed at the top approves the rules; the
per-subagent audit remains in
`subagent-system/spec.md` and may be edited without
re-opening this ADR.
