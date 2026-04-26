# Business-Analyst Decision Log — 2026-04-26

> Decisions taken in `auto` mode while reverse-engineering kiss-u
> feature specifications. One entry per non-trivial decision.
> Trivial wording / formatting choices are not logged.

## DEC-001 — Feature decomposition: 10 features as listed in the brief

- **Kind:** alternative-picked.
- **Context:** The brief proposed 10 features and invited collapsing
  / expanding. Reading the architecture extraction (`docs/architecture/extracted.md`),
  the C4 components, and the API docs, I confirmed all 10 map
  cleanly to distinct user-facing concerns and source-tree
  modules. No collapse / expansion needed.
- **Decision:** Keep all 10 features:
  `kiss-init`, `kiss-upgrade`, `kiss-install`, `kiss-uninstall`,
  `preset-management`, `extension-management`, `workflow-engine`,
  `integration-system`, `agent-skills-system`,
  `build-and-distribution`.
- **Trade-offs:** `kiss-install` / `kiss-uninstall` overlap with
  `integration-system`. Specs cross-link rather than duplicate;
  per-feature specs scope tightly to their command surface, while
  `integration-system` carries the cross-cutting contract
  (`IntegrationBase`, manifests, format families).

## DEC-002 — `kiss-upgrade` spec covers the documented flow, not a non-existent command

- **Kind:** alternative-picked + autonomous-action.
- **Context:** `docs/upgrade.md:49-57` references `kiss upgrade`,
  but `src/kiss_cli/cli/` exposes only `kiss integration upgrade`.
  The documented "Part 2: Updating Project Files" flow is
  `kiss init --here --force --ai <agent>`.
- **Decision:** Spec `kiss-upgrade` describes the documented
  upgrade workflow as it works today (`kiss init --here --force`
  + per-integration `kiss integration upgrade`). Logged the
  command-vs-doc gap as **RDEBT-001** so the human owner can
  decide whether to add a real `kiss upgrade` alias or rewrite
  the docs.

## DEC-003 — Treat Principle III violations as "current state" facts

- **Kind:** debt-overridden.
- **Context:** Standards Principle III caps function size at 40
  exec LOC and complexity at ≤ 10. `extensions.py` (2,493 LOC)
  and `presets.py` (2,098 LOC) are in violation.
- **Decision:** Spec NFR sections state Principle III as the
  target-state constraint and call out the current violation as
  a known debt that maps to TDEBT-003 / TDEBT-004 / TDEBT-022 and
  ADR-013 / ADR-014. Logged **RDEBT-007** so the human can
  confirm whether specs are being signed off against the current
  (violating) state or the post-decomposition target state.

## DEC-004 — NFR coverage value is taken straight from the standards

- **Kind:** default-applied.
- **Context:** `docs/standards.md:97-99` states ≥ 80% line
  coverage on changed files. `pyproject.toml` does not pin a
  threshold (TDEBT-015). Specs need an NFR figure.
- **Decision:** Use 80% in every spec NFR. Logged **RDEBT-006**
  to confirm the value at sign-off.

## DEC-005 — Performance NFR for `kiss init` left qualitative

- **Kind:** default-applied.
- **Context:** `docs/architecture/intake.md:134-136` records "no
  formal SLO". Brief told me to log RDEBT when the architecture
  intake gives no target.
- **Decision:** Spec uses qualitative wording ("completes within
  seconds on a developer laptop"). Logged **RDEBT-002** for the
  pin.

## DEC-006 — `kiss install` / `kiss uninstall` features describe `kiss integration install` / `kiss integration uninstall`

- **Kind:** alternative-picked.
- **Context:** No top-level `kiss install` / `kiss uninstall`
  commands exist (verified via `ls src/kiss_cli/cli/`). The
  brief's feature list mentions them. The actual surface is
  under `kiss integration <…>` (`cli/integration.py:181-343`).
- **Decision:** Spec the features under the brief's names but
  describe the actual sub-Typer commands. Logged **RDEBT-019**
  so the naming can be regularised.

## DEC-007 — Treat asset-integrity verification as an aspirational FR, not a current one

- **Kind:** alternative-picked.
- **Context:** `_integrity.verify_asset_integrity` exists
  (`_integrity.py:24-79`) but no production caller was found
  (per `extracted.md:74-77`).
- **Decision:** Spec FRs describe asset integrity as an
  invariant (per ADR-007 / TDEBT-002) but flag the current gap
  as **RDEBT-003**. Specs do not invent a runtime call site;
  they state what *should* hold, with evidence pointing at the
  ADR.

## DEC-008 — Feature scope: `agent-skills-system` covers per-skill bundling, not authoring

- **Kind:** alternative-picked.
- **Context:** The codebase has `agent-skills/` (49 bundles,
  authoritative source) and per-AI install layouts (e.g.
  `.claude/skills/`). These are two concerns: (a) authoring a
  skill (out of scope — that is a developer / team artefact)
  and (b) installing skill bundles into per-AI trees (in scope
  — driven by `skill_assets.py` + each integration's setup).
- **Decision:** Spec scopes `agent-skills-system` to
  installation, layout, and the per-AI mapping contract. Skill
  authoring is captured as Out-of-scope.

## DEC-009 — subagents are folded into `agent-skills-system`

- **Kind:** alternative-picked.
- **Context:** `installer.py:429-494` deploys role-agent prompts
  (architect, developer, …) from `subagents/`. They are not
  skills, but they share the install-target story.
- **Decision:** Cover subagents as a second sub-concern of
  `agent-skills-system`. Logged **RDEBT-020** for the per-
  integration target-folder rules, which are not fully
  documented.

## DEC-010 — Catalog (community) features included in each manager's spec

- **Kind:** autonomous-action.
- **Context:** Each of `extension`, `preset`, `workflow`,
  `integration` exposes a `catalog` subcommand. The brief's
  feature list folded these into their respective management
  features.
- **Decision:** Catalog management is included in each
  feature's spec as a secondary user story. Logged **RDEBT-022**
  (trust model) and **RDEBT-023** (catalog network access vs.
  offline guarantee) for the human to confirm.

## DEC-011 — Generic integration's commands-dir requirement specced as FR

- **Kind:** alternative-picked.
- **Context:** `cli/init.py:210-213` enforces that
  `--integration generic` requires
  `--integration-options="--commands-dir <dir>"`.
- **Decision:** Spec the requirement and its error message.
  Logged **RDEBT-008** because the directory's expected
  contents and creation semantics are not documented.

## DEC-012 — Single-integration vs. multi-integration policy difference acknowledged

- **Kind:** alternative-picked.
- **Context:** `kiss init` allows multiple integrations
  (`cli/init.py:191-206`); `kiss integration install` errors if
  one is already installed (`cli/integration.py:214-217`).
- **Decision:** Specs reflect the asymmetry as observed.
  **RDEBT-009** logs the question "is this intended?".

## DEC-013 — Spec authoring deviates slightly from the kiss-specify template

- **Kind:** autonomous-action.
- **Context:** The brief asks for additional sections (Problem
  Statement, Functional Requirements with FR-NNN numbering,
  Edge Cases, Out-of-scope, Key Entities, Traceability footer)
  beyond the spec-template defaults. The template has User
  Scenarios and Success Criteria but does not pre-print FR
  numbers as section headers.
- **Decision:** Use the brief's structure (Problem Statement →
  User Scenarios with priorities → Functional Requirements
  (FR-NNN with file:line citations) → Non-Functional
  Requirements → Acceptance Criteria (Given/When/Then) → Edge
  Cases → Out-of-scope → Key Entities → Assumptions →
  Traceability footer). The kiss-specify template's section
  ordering is preserved where it overlaps; mandatory sections
  are kept.

## DEC-014 — `kiss check` is documented inside `integration-system`, not as a separate feature

- **Kind:** alternative-picked.
- **Context:** The brief's 10-feature list does not name
  `kiss check`. The command (`cli/check.py:1-639`) validates
  installed integrations, skills, and `.kiss/context.yml`.
- **Decision:** Fold `kiss check` into `integration-system`
  (the natural home, since most checks target integrations and
  the manifest layout). Mention as a "diagnostics" user story
  rather than a separate feature.

## DEC-015 — `kiss workflow run/resume/status/list/add/remove/search/info` and `kiss workflow catalog` go into `workflow-engine`

- **Kind:** alternative-picked.
- **Context:** Could split "engine + step types" (the runtime
  semantics) from "workflow management" (lifecycle commands).
- **Decision:** Single feature `workflow-engine` covers both,
  scoped to: 10 step types, declarative YAML, lifecycle
  commands, catalog. Cross-cuts to extensions / integrations
  via the `command` step are noted but not duplicated.

## DEC-016 — Feature priorities (P1/P2/P3) chosen by user-impact

- **Kind:** default-applied.
- **Context:** Each spec needs P1/P2/P3 user-story priorities.
  No user-supplied ranking exists.
- **Decision:** Apply this ordering across specs:
  - P1 = the headline command for the feature (e.g. for
    `kiss-init`: scaffold a fresh project).
  - P2 = the most common variant / second most-used story.
  - P3 = edge / advanced / rarely-used flows.
  Specifically called out per spec.

## DEC-017 — Specs assert "offline after install" as a hard invariant

- **Kind:** default-applied.
- **Context:** ADR-003, `tests/test_offline.py`, and the
  standards all converge on offline-after-install.
- **Decision:** Every relevant spec lists offline operation as
  an NFR. Catalog-update flows (which may require network) are
  flagged as **RDEBT-023** so the boundary is explicit.

## DEC-018 — "Each `kiss <subcommand>` is a candidate feature" honoured but not duplicated

- **Kind:** alternative-picked.
- **Context:** The brief says "each `kiss <subcommand>` is a
  candidate feature". Strictly applied, that would be ~30
  specs. The brief also asked for natural feature boundaries.
- **Decision:** Group sub-Typer commands under their feature
  spec (e.g. `preset list/add/remove/search/resolve/info/
  set-priority/enable/disable` and `preset catalog
  list/add/remove` all live in `preset-management/spec.md` as
  separate user stories). This keeps spec count to 10 while
  preserving every command in FRs.

## DEC-019 — `kiss version` and `kiss --version` are mentioned in `build-and-distribution`

- **Kind:** alternative-picked.
- **Context:** `kiss version` (`cli/version.py:12-39`) and
  `kiss --version` (`cli/__init__.py:24`) are diagnostic /
  build-info commands, not feature commands.
- **Decision:** Cover them under `build-and-distribution` as a
  short user story (the user wants to know which version is
  installed). Avoids creating an 11th spec for two trivial
  commands.

## DEC-020 — Edge-case template: minimum 6 cases per spec

- **Kind:** default-applied.
- **Context:** Brief requires at minimum: missing config,
  conflicting integrations, network unavailable, permission
  denied, manifest mismatch, partial install rollback.
- **Decision:** Every spec lists a minimum of 6 edge cases,
  selecting from the brief's mandatory list plus feature-
  specific additions. Where an expected behaviour is observable
  in the code, it is cited; where it is not documented, an
  RDEBT is logged.

## DEC-021 — Narrow integration scope to seven AIs (ADR-018 record)

- **Kind:** alternative-picked.
- **Context:** User provided `docs/AI-urls.md` on
  2026-04-26 as the authoritative supported-AI list. It
  lists exactly seven AI providers (Claude Code, GitHub
  Copilot, Cursor Agent, OpenCode, Windsurf, Gemini CLI,
  Codex) plus the agentskills.io specification. The
  current source code registers 13 integrations.
- **Decision:** Reduce supported AIs from 13 → 7 in
  `integration-system/spec.md` FR-016 / FR-017; add ADR-018
  (`Proposed`); flag spec / code divergence as RDEBT-024
  (spec) and TDEBT-028 (architecture). The source-code
  narrowing pass is deferred — this is a docs-only update.
- **Trade-offs:** Spec leads code by one cycle; users on
  the six removed integrations (`kiro_cli`, `auggie`,
  `tabnine`, `kilocode`, `agy`, `generic`) still get the
  legacy behaviour on the current binary. Migration
  guidance is part of the future source-code pass.

## DEC-022 — Split agent-skills-system spec into two

- **Kind:** alternative-picked.
- **Context:** Per the user's clarification on 2026-04-26
  ("role-agent prompts are actually subagents"), the
  previous `agent-skills-system/spec.md` conflated two
  surfaces: the agent-skills bundles (`agent-skills/kiss-*`)
  and the role-agent / subagent prompts
  (`subagents/<role>.md`). Each AI provider treats them
  as distinct concerns (Claude / Cursor / Gemini /
  OpenCode / Codex have separate `agents/` folders;
  Copilot calls them subagents; Windsurf calls them
  workflows).
- **Decision:** Trim `agent-skills-system/spec.md` to cover
  skills only (49 bundles, agentskills.io conformance,
  per-AI install layout, manifest contract); create
  `subagent-system/spec.md` to cover the 14 role-agent
  prompts under `subagents/`, the per-AI subagent
  format (Markdown for six, TOML for Codex), the per-AI
  agent file (`CLAUDE.md` / `AGENTS.md` / `GEMINI.md`),
  the two-mode UX, and the work-type output convention.
  The two specs MUST NOT have overlapping FRs and
  cross-link via the traceability footer.
- **Trade-offs:** Considered a third "shared infrastructure"
  spec to host the work-type output convention + two-mode
  UX (since both apply to subagents only). Picked the
  simpler two-spec split: keep the work-type / two-mode
  content inside `subagent-system/spec.md` because that's
  the only consumer. A third spec would add a fan-out
  without saving FR cross-references.

## DEC-023 — Map Windsurf workflows to subagents (default-applied with RDEBT)

- **Kind:** default-applied.
- **Context:** `docs/AI-urls.md` lists
  `docs.windsurf.com/windsurf/cascade/workflows` for
  Windsurf with the annotation "similar to subagents".
  WebFetch confirmed workflows are `.md` files under
  `.windsurf/workflows/` with a 12 000-char ceiling and
  manual `/<name>` invocation — not a one-to-one match
  for the classic subagent semantics.
- **Decision:** Map Windsurf workflows to subagents in
  `subagent-system/spec.md` Key Entities + FR-003 as the
  closest analogue. Logged as **RDEBT-025** so the user
  can confirm the mapping and decide whether the
  12 000-char ceiling forces prompt summarisation.

## DEC-024 — Map Copilot subagents to subagents (default-applied)

- **Kind:** default-applied.
- **Context:** `docs/AI-urls.md` annotates the VS Code
  Copilot `code.visualstudio.com/docs/copilot/customization/
  subagents` page with "similar to subagents".
  WebFetch confirmed subagents are `*.agent.md` files
  under `.github/agents/` (or `.claude/agents/` via
  cross-agent fallback) with optional YAML frontmatter
  including `name`, `description`, `tools`, `model`,
  `agents`, `handoffs`, `user-invocable`,
  `disable-model-invocation`, and `hooks`.
- **Decision:** Treat VS Code Copilot subagents as the
  Copilot subagent surface in `subagent-system/spec.md`
  Key Entities + FR-003. Whether the kiss installer today
  actually targets `.github/agents/<role>.agent.md` (and
  not the older skills folder) is logged as RDEBT-027.

## DEC-025 — Write per-AI research summary at docs/research/

- **Kind:** autonomous-action.
- **Context:** The brief offered an optional research
  summary as a deliverable. The seven-AI scope narrowing
  rests on facts the WebFetch produced, and those facts
  feed FR-016 in `integration-system/spec.md`,
  Key Entities in `subagent-system/spec.md`, and the
  per-AI install layout in `agent-skills-system/spec.md`.
  Without a single artefact citing those facts, every
  consumer spec would have to recite them.
- **Decision:** Wrote
  `docs/research/ai-providers-2026-04-26.md` (≈ 100 lines)
  with one row per AI capturing the agent-file, the
  skills format, and the subagent format, plus a removed-
  from-scope section listing the six unsupported
  integrations. Specs cite this artefact in their
  Traceability footers.

## DEC-026 — Author ADR-018 even though "narrowing scope" was not user-named

- **Kind:** autonomous-action.
- **Context:** The brief asked to "Add a new ADR if the
  narrowing itself deserves a record" and proposed
  `ADR-018-narrow-integration-scope-to-seven-ais`. The
  scope narrowing has cross-cutting consequences (every
  spec, every C4 doc, several existing ADRs need
  cross-references), so a single discoverable record is
  worth the file.
- **Decision:** Authored
  `docs/decisions/ADR-018-narrow-integration-scope-to-
  seven-ais.md` in `Proposed` status with decider
  `(decider: TBD — confirm)`. The ADR records the seven
  URLs (per AI) that justify the cut, the six removed
  integrations, and the spec / code divergence. The agent
  did not flip the status to `Accepted`.

## DEC-027 — Adopt the Claude Code reserved-words ban universally (not per-provider)

- **Kind:** alternative-picked.
- **Context:** Claude Code best-practices forbid the
  tokens `anthropic` and `claude` in the `name:`
  frontmatter; the other six supported providers
  (Copilot, Cursor, OpenCode, Windsurf, Gemini CLI,
  Codex) and agentskills.io itself say nothing about
  reserved words. The KISS source-of-truth is one
  `kiss-<name>.md` per skill, rendered into the per-AI
  tree by the format-aware writer (FR-002, ADR-005).
  Per-provider rendering of the `name:` field would
  contradict that single-source design.
- **Decision:** Sided with the strictest provider
  (Claude Code) — banned both reserved words from
  KISS-managed skill names universally. This forces
  one rename in the audit (`claude-api` →
  `kiss-anthropic-sdk`) but keeps the format-writer
  contract clean. Logged as RDEBT-030 so the user can
  flip to per-provider rendering if the rename cost is
  unacceptable.

## DEC-028 — Keep the `kiss-` prefix as a namespace marker

- **Kind:** alternative-picked.
- **Context:** No supported provider prescribes a prefix;
  none forbids one. The `kiss-` prefix has a real
  installer-side role: `kiss integration uninstall` and
  `kiss upgrade` filter the per-integration manifest by
  this prefix to identify installer-managed skills, which
  lets user-authored skills coexist in the same
  `.<provider>/skills/` folder safely. Removing the
  prefix would force the installer to track ownership in
  a sidecar file or risk wiping user-authored skills on
  uninstall.
- **Decision:** Recorded "KEEP `kiss-` prefix" in
  ADR-019 §Decision rule 9 and `agent-skills-system/
  spec.md` FR-017. This makes the 5 non-`kiss-` skills
  (`simplify`, `claude-api`, `init`, `review`,
  `security-review`) targets for RENAME proposals in
  the Naming Audit Appendix. Three of them (`init`,
  `review`, `security-review`) are flagged as
  NEEDS-DECISION because they MAY be re-exports of
  Claude Code's vendor built-in slash commands — see
  RDEBT-029.

## DEC-029 — Naming style: verb-then-noun preferred, gerund accepted (not enforced)

- **Kind:** default-applied.
- **Context:** Claude Code best-practices recommend
  gerund form (verb + -ing, e.g. `processing-pdfs`) but
  list verb-then-noun (`process-pdfs`) and noun-phrase
  (`pdf-processing`) as acceptable. The other six
  providers prescribe no style. The 49 existing KISS
  skills consistently use verb-then-noun
  (`kiss-codebase-scan`, `kiss-clarify-specs`).
- **Decision:** Adopt verb-then-noun as the KISS house
  style; gerund accepted but not required. This avoids
  a 49-skill rename for marginal benefit (mass renaming
  to `kiss-clarifying-specs`, `kiss-scanning-codebase`,
  etc. would not improve discovery — the existing names
  already pass Claude Code best-practices' "acceptable
  alternatives" branch). Logged as RDEBT-030 so the
  user can flip the rule.

## DEC-030 — Keep the KISS `templates/` synonym for `assets/templates/`

- **Kind:** alternative-picked.
- **Context:** agentskills.io specifies optional
  sub-directories `scripts/`, `references/`, `assets/`
  in a skill bundle. The existing KISS bundles use
  `templates/` at the skill root (a flat alias for the
  `assets/templates/` slot — same role, shorter path).
  Renaming every existing skill's `templates/` to
  `assets/templates/` would touch every bundle and
  every cross-reference inside skill prompts.
- **Decision:** Permit `templates/` as a KISS-specific
  synonym alongside `assets/`. Codified in FR-016 of
  `agent-skills-system/spec.md`. The path stays
  shorter; agentskills.io's compliance validator
  (`skills-ref validate`) does not enforce a closed
  set of sub-directories ("Any additional files or
  directories" per the spec), so this is conformant.
  The decision is recorded so the source-side rename
  pass (TDEBT-029) does NOT have to relocate every
  skill's templates.

## DEC-031 — Author ADR-019 + audit appendix pattern (not 15 separate ADRs)

- **Kind:** autonomous-action.
- **Context:** The brief asked for "one new ADR" and
  for the audit to live in `agent-skills-system/spec.md`.
  An alternative would be one ADR per rename (≈ 15
  ADRs), which would make every individual rename a
  trackable decision but flood the decision register.
- **Decision:** Single ADR-019 records the **rules**
  adopted (R1 … R6); the per-skill audit table lives
  inside the spec because the table is expected to
  change as new skills land or descriptions get
  rewritten. This keeps the ADR count proportional to
  the number of distinct architectural rules adopted,
  not to the number of skills affected.

## DEC-032 — Mark `init` / `review` / `security-review` as NEEDS-DECISION (not RENAME)

- **Kind:** alternative-picked.
- **Context:** The three bare-generic non-`kiss-` skills
  collide with Claude Code's own built-in slash commands
  (`/init`, `/review`, `/security-review`). Two readings
  are reasonable:
  1. They are KISS-bundled skills that happen to share
     names with vendor built-ins → RENAME with
     namespace prefix (`kiss-claude-md-init`,
     `kiss-pr-review`, `kiss-pr-security-review`).
  2. They are vendor-built-in re-exports that KISS
     packages for distribution → EXEMPT from FR-015 via
     an explicit allow-list, leave the names bare.
- **Decision:** Marked as **NEEDS-DECISION** in the
  audit, not silently renamed. Both interpretations
  are recorded; the user picks. Logged as part of
  RDEBT-029.

## DEC-033 — Author ADR-020 as the subagent-side mirror of ADR-019

- **Kind:** alternative-picked.
- **Context:** The brief asks the subagent-system spec
  to be extended with the same shape ADR-019 + the
  agent-skills-system spec's Naming Audit Appendix
  applied to agent-skills. Two structural options:
  (a) merge the subagent rules into ADR-019 so a
  single ADR governs both surfaces; (b) author a
  separate ADR-020 that mirrors ADR-019's shape but
  lives independently. Option (a) reads compact but
  conflates skills (`agent-skills/kiss-*` namespace,
  `kiss-` prefix policy, reserved-words ban) with
  subagents (`subagents/<role>` namespace, no
  prefix, no reserved-words ban). The two surfaces
  share rules (kebab-case, single-purpose, frontmatter
  `name`/`description`) but differ on enough to
  warrant separate ADRs.
- **Decision:** Authored **ADR-020** as the
  subagent-side mirror. Cross-link to ADR-019
  (sibling). Each ADR can flip to `Accepted`
  independently. The `kiss-` prefix divergence
  (skills YES, subagents NO) is documented in
  ADR-020 §9 with its own rationale.

## DEC-034 — DO NOT propagate role-name renames into subagents/ or other specs

- **Kind:** debt-overridden.
- **Context:** The audit table flags four NEEDS-DECISION
  rows (`architect`, `developer`, `tester`, `devops`)
  where action-oriented or namespace-prefixed names
  would arguably read better. Per the brief's
  ground-rule "Never rename in source code or in
  `subagents/`. Specs only.", and the explicit
  instruction "Do NOT propagate renames into
  `architect.md` / `business-analyst.md` / etc.
  references in other specs — those propagations wait
  until ADR-020 is `Accepted`."
- **Decision:** The Naming Audit Appendix lists the
  four NEEDS-DECISION rows with proposed alternatives
  but does NOT pick a winner; ADR-020 is `Proposed`,
  not `Accepted`; no on-disk file under
  `subagents/` is renamed; no other spec's
  references to role names are edited. Logged as
  RDEBT-032 (style) + RDEBT-033 (prefix), with
  TDEBT-030 covering the eventual source-side pass
  + RDEBT-035 covering the spec/code divergence.

## DEC-035 — Drop `kiss-` prefix policy for subagents (asymmetric with skills)

- **Kind:** alternative-picked.
- **Context:** ADR-019 §9 KEEPs the `kiss-` prefix on
  agent-skills as a namespace + manifest-filter
  marker. The natural symmetry would be to apply the
  same prefix to all 14 subagent role names
  (`kiss-architect`, `kiss-developer`, …). Reading
  the seven provider docs:
  - Subagent folders (`.<provider>/agents/`) are
    project-managed, often empty at install time.
    User-authored subagents are rare in the docs'
    examples.
  - The `agent-decisions/<agent-name>/` decision-log
    path is widely cross-referenced; flipping every
    name to `kiss-<agent>` invalidates every
    existing cross-spec reference.
  - The collision risk is built-in provider agents
    (Codex `default`/`worker`/`explorer`; future
    Claude Code / Cursor reservations), not user
    agents. A `kiss-` prefix doesn't protect against
    a future Claude Code reservation of the
    `kiss-architect` name (unlikely but possible).
  - ADR-019's prefix rationale ("uninstall safety +
    installer manifest filter") applies only to
    skills because skill folders mix user-authored
    + KISS bundles in the same dir. Subagent folders
    don't mix the same way today.
- **Decision:** ADR-020 §9 explicitly KEEPs subagent
  names UNPREFIXED; the asymmetry with skills is
  documented in the ADR Consequences and in
  RDEBT-033 so the decider can flip if the user
  prefers symmetry over the four points above.

## DEC-036 — Default audit verdict to KEEP unless a published rule is violated

- **Kind:** default-applied.
- **Context:** The brief asks for KEEP / RENAME /
  NEEDS-DECISION verdicts. The seven WebFetched
  provider docs give conflicting style guidance
  (role-oriented vs action-oriented), so a strict
  reading could grade ALL 14 as either KEEP (Cursor
  preference) or RENAME (OpenCode preference). The
  brief also says "Don't unilaterally re-orient —
  surface the question."
- **Decision:** Graded a row as RENAME ONLY if the
  current name violates a rule that has NO
  counter-rule from another supported provider.
  Outcome: **0 RENAME** verdicts. Style differences
  → NEEDS-DECISION (4 rows: `architect`,
  `developer`, `tester`, `devops`). Sibling-pair
  disambiguation (`tester` ↔ `test-architect`,
  `code-quality-reviewer` ↔ `code-security-reviewer`,
  `product-owner` ↔ `project-manager` ↔
  `scrum-master`) → KEEP with a description-tightening
  flag (RDEBT-034), not RENAME.

## DEC-037 — Per-provider frontmatter rendering belongs in the installer, not in the bundled prompt

- **Kind:** alternative-picked.
- **Context:** Three reasonable shapes for the
  bundled `<role>.md`:
  1. Single Claude Code-shaped frontmatter; installer
     renders per-provider on install. (CURRENT.)
  2. Multi-provider frontmatter — every provider's
     keys merged into one block; installer filters.
  3. Per-provider sub-folders under `subagents/`
     (`subagents/claude/architect.md`,
     `subagents/codex/architect.toml`, …).
  Option (2) bloats every prompt with rarely-used
  keys (`mode: subagent`, `developer_instructions`).
  Option (3) explodes the bundle to 14 × 7 = 98
  files, kills authoring ergonomics, and breaks the
  "single source per role" invariant in
  `subagent-system/spec.md` Out of Scope.
- **Decision:** ADR-020 §5 / FR-014 mandates option
  (1): single Claude Code-shaped bundled prompt;
  installer carries the per-provider rendering
  branch table. Cost: the installer gains seven
  rendering branches; a new test
  `tests/test_subagent_compliance.py` enforces
  determinism (TDEBT-030).

## DEC-038 — Description-tightening pass is RDEBT, not silent edit

- **Kind:** default-applied.
- **Context:** All 14 current `description:` blocks
  exceed the 200–600 char recommended length cited
  by Claude Code best-practices. The brief's
  whitelist allows writes to
  `docs/specs/subagent-system/spec.md`, but the
  on-disk role-prompt files under `subagents/`
  are explicitly forbidden. A spec-side rewrite of
  the descriptions would create a divergence
  between the audit appendix's "tightened
  descriptions" and the real prompts shipping in the
  wheel.
- **Decision:** Did NOT rewrite any of the 14
  `description:` blocks. The tightening work is
  documented as **RDEBT-034** with the recommended
  length + the sibling-disambiguation pairs that
  most need it. The source-side rewrite is part of
  TDEBT-030 once ADR-020 flips to `Accepted`.
