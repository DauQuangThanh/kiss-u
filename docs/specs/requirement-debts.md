# Requirements Debt Register

> Maintained by the `business-analyst` agent. Each entry has a unique
> `RDEBT-NNN` ID, a one-line summary, the open question, the spec(s)
> the debt surfaces in, related TDEBTs (if any), priority, and status.
> New entries append; entries close by editing their **Status**.

> Generated 2026-04-26 by `business-analyst` (auto mode), seeded from
> the reverse-engineering pass over the existing kiss-u codebase.

## Status legend

- **Open** — needs a human decision.
- **Resolved** — answered; recorded in the spec or an ADR.
- **Carried** — known and documented, no fix planned this cycle.

## Priority legend

- 🔴 Blocking — spec cannot be implemented until resolved.
- 🟡 Important — affects acceptance scope.
- 🟢 Can wait — clarification but not on a critical path.

## Entries

### RDEBT-001 — `kiss upgrade` is documented but not implemented as a top-level command

- **Question:** `docs/upgrade.md:49-57` describes a `kiss upgrade`
  command, but `src/kiss_cli/cli/` exposes only
  `kiss integration upgrade` (`cli/integration.py:472-…`). The
  documented `Part 2: Updating Project Files` flow tells the user
  to run `kiss init --here --force --ai <agent>` instead. Should a
  thin `kiss upgrade` alias be added, or should the docs be
  rewritten to drop the `kiss upgrade` reference?
- **Surface:** `docs/specs/kiss-upgrade/spec.md`,
  `docs/upgrade.md:49-57`.
- **Priority:** 🟡 Important.
- **Status:** Open.

### RDEBT-002 — No quantified performance NFR for `kiss init`

- **Question:** `docs/architecture/intake.md:134-136` records
  `kiss init` as "should complete in seconds on a developer
  laptop" with no formal SLO. Spec acceptance criteria currently
  use the qualitative "completes within seconds" wording. Pin a
  wall-clock budget (e.g. ≤ 10 s on a 2024-era laptop with SSD)?
- **Surface:** `docs/specs/kiss-init/spec.md`,
  `docs/specs/kiss-upgrade/spec.md`,
  `docs/specs/build-and-distribution/spec.md`.
- **Cross-link:** TDEBT-017.
- **Priority:** 🟢 Can wait.
- **Status:** Open.

### RDEBT-003 — Asset integrity verification is implemented but not wired

- **Question:** `_integrity.verify_asset_integrity` exists at
  `src/kiss_cli/_integrity.py:24-79` but no `kiss` subcommand
  invokes it during normal flow (per
  `docs/architecture/extracted.md:74-77`). Spec FRs treat asset
  integrity as a guarantee, but in practice it is unenforced at
  runtime. Should every `kiss init` / `kiss integration upgrade`
  call it before reading the bundle?
- **Surface:** `docs/specs/kiss-init/spec.md`,
  `docs/specs/build-and-distribution/spec.md`,
  `docs/specs/integration-system/spec.md`.
- **Cross-link:** TDEBT-002, TDEBT-023, ADR-007.
- **Priority:** 🟡 Important.
- **Status:** Resolved (2026-04-26). Wired into `cli/init.py`
  and `cli/integration.py` upgrade path.

### RDEBT-004 — 13 vs 14 integration count discrepancy

- **Question:** `integrations/__init__.py:50-81` registers 13
  integrations; `CLAUDE.md` and the README state "14 AI providers".
  Specs use "13 (or 14 with Generic)". Confirm which count is the
  user-facing number, and whether `Generic` is positioned as a
  branded provider in marketing materials.
- **Surface:** `docs/specs/integration-system/spec.md`,
  `docs/specs/kiss-init/spec.md`.
- **Cross-link:** TDEBT-008, ANALYSISDEBT-005.
- **Priority:** 🟢 Can wait.
- **Status:** Resolved (2026-04-26). Registry narrowed to 7 AIs;
  6 removed packages deleted. Count is exactly 7.

### RDEBT-005 — macOS support claim vs. CI matrix

- **Question:** Standards / CLAUDE.md claim macOS support; the CI
  test matrix (`.github/workflows/test.yml:30-55`) only runs
  `ubuntu-latest` and `windows-latest`. Specs name macOS as a
  supported OS in Assumptions. Confirm whether macOS is a
  first-class target or a best-effort target.
- **Surface:** every spec's NFR section.
- **Cross-link:** TDEBT-014.
- **Priority:** 🟡 Important.
- **Status:** Open.

### RDEBT-006 — Coverage threshold not pinned

- **Question:** Standards demand ≥ 80% line coverage on changed
  files; `pyproject.toml` does not configure a `--cov-fail-under`
  threshold. Specs write the 80% figure into NFRs but it is not
  CI-enforced. Pin the value before signing off any spec.
- **Surface:** every spec's NFR section.
- **Cross-link:** TDEBT-015.
- **Priority:** 🟡 Important.
- **Status:** Open.

### RDEBT-007 — Standards violation: hot files exceed function/module limits

- **Question:** Standards Principle III caps functions at ≤ 40
  exec LOC, complexity ≤ 10. `extensions.py` (2,493 LOC) and
  `presets.py` (2,098 LOC) are orders of magnitude over.
  Spec NFRs state Principle III as a constraint, but the existing
  implementation does not satisfy it. Confirm: do specs assert
  Principle III is "current" (reverse-engineered violation) or
  "post-decomposition" (after ADR-013 / ADR-014)?
- **Surface:** `docs/specs/extension-management/spec.md`,
  `docs/specs/preset-management/spec.md`,
  `docs/specs/integration-system/spec.md`.
- **Cross-link:** TDEBT-003, TDEBT-004, TDEBT-022, ADR-013,
  ADR-014.
- **Priority:** 🟡 Important.
- **Status:** Open.

### RDEBT-008 — Generic integration's `--commands-dir` semantics

- **Question:** `cli/init.py:210-213` requires
  `--integration-options="--commands-dir <dir>"` when
  `--integration generic` is selected. The exact directory
  semantics (must exist? created? relative to project root?
  contains what files?) are not spelled out in `docs/`.
- **Surface:** `docs/specs/kiss-init/spec.md`,
  `docs/specs/integration-system/spec.md`.
- **Priority:** 🟡 Important.
- **Status:** Moot (2026-04-26). The `generic` integration was
  removed from the source code per ADR-018 / RDEBT-024.

### RDEBT-009 — `kiss integration install` refuses while another is installed — by design or by accident?

- **Question:** `cli/integration.py:214-217` errors out if any
  other integration is already installed; the user must run
  `kiss integration switch` instead. But `kiss init` happily
  installs *multiple* integrations in one go
  (`cli/init.py:191-206`). Why is the post-init policy single-
  integration when init allows N? Confirm intent.
- **Answer (2026-04-26):** Multi-integration is the intended
  model. `kiss integration install` MUST allow adding an
  integration alongside existing ones. Each integration owns a
  disjoint directory tree and a separate manifest. The code at
  `cli/integration.py:214-217` needs to be updated to remove
  the single-integration refusal. Updated specs:
  `kiss-install/spec.md` FR-004 + User Story 2,
  `kiss-uninstall/spec.md` FR-003/FR-005/FR-010,
  `integration-system/spec.md` Assumptions + Edge Cases.
- **Surface:** `docs/specs/kiss-install/spec.md`,
  `docs/specs/integration-system/spec.md`.
- **Priority:** 🟡 Important.
- **Status:** Resolved.

### RDEBT-010 — Manifest mismatch on upgrade — exact resolution policy

- **Question:** `cli/integration.py:528-535` lists modified files
  and aborts unless `--force`. The spec currently states "user can
  re-run with --force". Should there be a third option (interactive
  per-file resolution / merge)? `docs/upgrade.md:115-126`
  recommends a manual `cp` backup as the workaround.
- **Surface:** `docs/specs/integration-system/spec.md`,
  `docs/specs/kiss-upgrade/spec.md`.
- **Priority:** 🟢 Can wait.
- **Status:** Open.

### RDEBT-011 — Workflow engine: `command` step requires an installed integration

- **Question:** `STEP_REGISTRY` includes a `command` step
  (`workflows/__init__.py:43-65`) that dispatches via
  `IntegrationBase.dispatch_command`
  (`integrations/base.py:147-225`). What's the expected behaviour
  if no integration is installed when a workflow runs? Error?
  Skip? Auto-fall-back to a different integration?
- **Surface:** `docs/specs/workflow-engine/spec.md`.
- **Cross-link:** TDEBT-010.
- **Priority:** 🟡 Important.
- **Status:** Open.

### RDEBT-012 — Workflow concurrency / parallelism guarantees

- **Question:** `fan-out` and `fan-in` step types
  (`workflows/__init__.py:43-65`) suggest parallel execution. The
  spec needs a clear statement: are fan-out branches truly
  concurrent (threads / processes) or sequential? What's the
  ordering / failure-isolation guarantee?
- **Surface:** `docs/specs/workflow-engine/spec.md`.
- **Priority:** 🟡 Important.
- **Status:** Open.

### RDEBT-013 — Extension hook execution security model

- **Question:** `HookExecutor` (`extensions.py:2063+`) shells out
  to extension-defined commands. The spec must state: does the
  user confirm before each hook runs? Is there a sandbox? An
  allow-list? Today the answer appears to be "no — the user
  trusts whatever extension they installed".
- **Surface:** `docs/specs/extension-management/spec.md`.
- **Priority:** 🟡 Important.
- **Status:** Open.

### RDEBT-014 — Preset priority semantics

- **Question:** `kiss preset set-priority`
  (`cli/preset.py:367-416`) accepts a priority integer. What does
  it order — install order? skill-override resolution? Both? The
  spec needs a clear consequence statement.
- **Surface:** `docs/specs/preset-management/spec.md`.
- **Priority:** 🟡 Important.
- **Status:** Open.

### RDEBT-015 — Partial-install rollback boundary

- **Question:** `cli/integration.py:248-256` rolls back on
  `kiss integration install` failure via `teardown(force=True)`.
  But `kiss init` installs multiple integrations in sequence
  (`cli/init.py:294-326`); if integration N succeeds and N+1
  fails, are 1..N rolled back too? Today the answer appears to be
  "no — only the project directory is removed if it was freshly
  created (`cli/init.py:506-507`)". Confirm intent and spec it.
- **Surface:** `docs/specs/kiss-init/spec.md`,
  `docs/specs/integration-system/spec.md`.
- **Priority:** 🟡 Important.
- **Status:** Open.

### RDEBT-016 — Permission denied on target directory: no documented behaviour

- **Question:** Specs include "permission denied on target dir"
  as an edge case. The code path (`cli/init.py:502-507`) catches
  any exception and removes the freshly-created dir, but the
  exact user-facing error wording / exit code / cleanup semantics
  for permission errors are not documented. Confirm expected
  behaviour.
- **Surface:** `docs/specs/kiss-init/spec.md`.
- **Priority:** 🟢 Can wait.
- **Status:** Open.

### RDEBT-017 — `kiss check` aggregate exit code semantics

- **Question:** `cli/check.py:613` exits with the maximum of three
  sub-checks. Does "max" mean "worst" (most severe failure) or
  literal numeric max? The exit-code conventions in
  `docs/analysis/api-docs.md` §5 list `0`, `1`, `130` — what
  values can the aggregate produce?
- **Surface:** `docs/specs/kiss-check/spec.md` FR-003.
  (Extracted from integration-system spec on 2026-04-26.)
- **Priority:** 🟢 Can wait.
- **Status:** Open.

### RDEBT-018 — PyPI publication intent

- **Question:** Specs reference "the wheel" as the distribution.
  Today only GitHub Releases are wired
  (`.github/workflows/release.yml:128-138`). Should the spec
  commit to PyPI (and to a public package name) or stay at
  "GitHub Releases only"?
- **Surface:** `docs/specs/build-and-distribution/spec.md`.
- **Cross-link:** TDEBT-018, TDEBT-019.
- **Priority:** 🟡 Important.
- **Status:** Open.

### RDEBT-019 — `kiss install` / `kiss uninstall` are not top-level commands

- **Question:** The reverse-engineering brief asked for
  `kiss-install` and `kiss-uninstall` features. The actual
  commands are `kiss integration install` and
  `kiss integration uninstall` (`cli/integration.py:181-343`).
  The specs have been written under the brief's names but
  describe the actual sub-Typer commands. Confirm the naming.
- **Surface:** `docs/specs/kiss-install/spec.md`,
  `docs/specs/kiss-uninstall/spec.md`.
- **Priority:** 🟡 Important.
- **Status:** Open.

### RDEBT-020 — subagents installation: which integrations get them?

- **Question:** `installer.py:429-494` installs role-agent
  prompts from `subagents/` into "each integration's agent
  dir". Not every integration has an agent dir — some are pure
  command/skill formats (e.g. Gemini's TOML commands). How does
  the installer decide where to put `architect.md`,
  `developer.md`, etc.? `(AI suggestion — confirm)` the answer
  may be "only into integrations that subclass
  `SkillsIntegration` / `MarkdownIntegration` with an
  `agents_folder`".
- **Surface:** `docs/specs/agent-skills-system/spec.md`,
  `docs/specs/integration-system/spec.md`.
- **Priority:** 🟡 Important.
- **Status:** Superseded by RDEBT-027 (resolved 2026-04-26).

### RDEBT-021 — Workflow `command` step error propagation

- **Question:** When a workflow `command` step's dispatched AI
  CLI exits non-zero, does the workflow halt? Continue? Retry?
  The standards' Principle II implies tests should pin this
  behaviour, but the user-facing contract is not in `docs/`.
- **Surface:** `docs/specs/workflow-engine/spec.md`.
- **Priority:** 🟡 Important.
- **Status:** Open.

### RDEBT-022 — Catalog (community) extensions / presets / integrations / workflows: trust model

- **Question:** Each manager exposes a `catalog` subcommand
  (`cli/extension.py:143-313`, `cli/preset.py:499-669`,
  `cli/workflow.py:526-592`) that lets users add additional
  catalogs. Are catalog entries verified (signature?
  reproducible build?) or is it "user-supplied URL ⇒ trusted"?
- **Surface:** `docs/specs/extension-management/spec.md`,
  `docs/specs/preset-management/spec.md`,
  `docs/specs/workflow-engine/spec.md`,
  `docs/specs/integration-system/spec.md`.
- **Priority:** 🟡 Important.
- **Status:** Open.

### RDEBT-023 — Offline-after-install scope: catalog updates require network?

- **Question:** Standards / ADR-003 commit to offline runtime.
  But community catalogs (RDEBT-022) imply pulling new entries
  from somewhere. Is `kiss <thing> catalog add <url>` allowed to
  hit the network, or must catalogs be supplied as local files?
  `tests/test_offline.py` defends the init flow only.
- **Surface:** `docs/specs/extension-management/spec.md`,
  `docs/specs/preset-management/spec.md`,
  `docs/specs/integration-system/spec.md`,
  `docs/specs/workflow-engine/spec.md`.
- **Cross-link:** TDEBT-007, ADR-003, ADR-017.
- **Priority:** 🟡 Important.
- **Status:** Open.

### RDEBT-024 — Spec narrows supported AIs to 7 but code still ships 13

- **Question:** ADR-018 (Proposed, 2026-04-26) narrows the
  supported AI integrations to seven (Claude Code, GitHub
  Copilot, Cursor Agent, OpenCode, Windsurf, Gemini CLI,
  Codex) per `docs/AI-urls.md`. The source code at
  `src/kiss_cli/integrations/__init__.py:14-84` and
  `integrations/catalog.json` still register 13 entries —
  the additional `kiro_cli`, `auggie`, `tabnine`,
  `kilocode`, `agy`, and `generic` are out of scope per the
  spec but still installable on the current binary. When
  does the source-code narrowing pass run, who is the
  decider that approves the user-visible breakage, and what
  is the migration story for users currently on one of the
  six removed integrations?
- **Surface:** `docs/specs/integration-system/spec.md`
  FR-016 / FR-017,
  `docs/specs/agent-skills-system/spec.md`,
  `docs/specs/subagent-system/spec.md`,
  `docs/specs/kiss-init/spec.md`,
  `docs/specs/kiss-install/spec.md`,
  `docs/specs/kiss-uninstall/spec.md`,
  `docs/specs/kiss-upgrade/spec.md`.
- **Cross-link:** TDEBT-028 (architecture mirror),
  ADR-018, RDEBT-004 (older 13-vs-14 question, superseded
  by this entry).
- **Priority:** 🔴 Blocking — every dependent spec assumes
  the seven-AI list as target state.
- **Status:** Resolved (2026-04-26). Source-code narrowing
  complete: 6 integration packages removed, registry contains
  exactly 7 AIs, catalog.json updated, all references cleaned.

### RDEBT-025 — Windsurf workflows ≈ subagents (mapping is approximate)

- **Question:** Per `docs/AI-urls.md` and the WebFetch
  pulled on 2026-04-26
  (`docs/research/ai-providers-2026-04-26.md`), Windsurf's
  closest analogue to a subagent is a `.windsurf/workflows/
  *.md` file (max 12 000 chars, manual `/<name>`
  invocation). Whether that mapping is semantically
  faithful (input contract, output contract, error
  propagation, model-invocation behaviour) is **(unverified
  — confirm)**. The 12 000-char ceiling means a verbose
  role-agent prompt may not fit; behaviour on overflow is
  also unknown.
- **Surface:** `docs/specs/subagent-system/spec.md`
  Edge Cases + Key Entities,
  `docs/specs/integration-system/spec.md` FR-016
  Windsurf row.
- **Priority:** 🟡 Important.
- **Status:** Open.

### RDEBT-026 — Per-AI agent file (`CLAUDE.md` / `AGENTS.md` / `GEMINI.md`) layout unverified against installer

- **Question:** Per `docs/AI-urls.md` and
  `docs/research/ai-providers-2026-04-26.md`, each of the
  seven supported AIs expects a specific top-level agent
  file: Claude → `<root>/CLAUDE.md`; Copilot, Cursor,
  OpenCode, Windsurf, Codex → `<root>/AGENTS.md`; Gemini
  → `<root>/GEMINI.md`. Whether the kiss installer
  actually writes the correct file per integration, with
  the `<!-- KISS START --> … <!-- KISS END -->` markers
  the upgrade flow expects, is **(unverified — confirm)**.
  The per-integration skill folder convention (e.g.
  whether kiss writes to `.claude/skills/`,
  `.cursor/skills/`, `.opencode/skills/`, etc., or to a
  cross-agent `.agents/skills/` fallback) is also
  **(unverified — confirm)**.
- **Surface:** `docs/specs/agent-skills-system/spec.md`
  Key Entities + User Story 2,
  `docs/specs/subagent-system/spec.md` FR-004,
  `docs/specs/integration-system/spec.md` FR-016 Skills
  format column.
- **Priority:** 🟡 Important.
- **Status:** Open.

### RDEBT-027 — Per-AI subagent install target / format unverified against installer source

- **Question:** `installer.py:429-494`
  (`install_custom_agents`) installs role-agent prompts
  from `subagents/` into "each integration's agent
  dir". Per
  `docs/research/ai-providers-2026-04-26.md`, the seven
  supported AIs expect different subagent layouts (e.g.
  Codex requires TOML, Windsurf maps subagents to
  `workflows/`, Copilot uses `*.agent.md`). Whether the
  current installer (a) chooses the correct target
  folder per integration, (b) renders to the correct file
  format (Markdown vs TOML), and (c) writes the right
  required-frontmatter fields per AI is **(unverified —
  confirm against installer source)**. This RDEBT
  supersedes the older **RDEBT-020** for the seven
  supported AIs.
- **Surface:** `docs/specs/subagent-system/spec.md`
  FR-003 / FR-004 / Edge Cases,
  `docs/specs/integration-system/spec.md` FR-014.
- **Priority:** 🔴 Blocking — every subagent-system FR
  depends on this answer.
- **Status:** Open.

### RDEBT-028 — Two-mode UX clause + AI-only scope coverage in role-agent prompts

- **Question:** Per CLAUDE.md "Every custom agent supports
  two modes" and "AI-only scoping for role skills and
  custom agents", every installed subagent prompt MUST
  contain (a) the `interactive` / `auto` mode UX clause
  with the decision-log path
  (`{paths.docs}/agent-decisions/<agent-name>/<YYYY-MM-DD>-
  decisions.md`), (b) the four decision kinds
  (`default-applied`, `alternative-picked`,
  `autonomous-action`, `debt-overridden`), and (c) the
  AI-only scope statement. Whether all 14 prompts under
  `subagents/` actually contain these clauses, and
  whether the installer preserves them in the per-AI
  rendering, is **(unverified — confirm)**.
- **Surface:** `docs/specs/subagent-system/spec.md`
  FR-005 / FR-008 / NFR-007.
- **Priority:** 🟡 Important.
- **Status:** Open.

### RDEBT-029 — NEEDS-DECISION items in the agent-skill naming audit

- **Question:** ADR-019 §"Naming Audit Appendix" (in
  `docs/specs/agent-skills-system/spec.md`) flags four
  ambiguous renames where best-practices admit two
  reasonable names. The user must pick one for each:
  - `kiss-adr` → `kiss-adr-author` *or* `kiss-author-adr`
    (or KEEP — bare-noun is borderline, not a clear
    violation).
  - `kiss-change-register` + `kiss-change-control` →
    keep both with tightened descriptions, *or* merge
    into a single `kiss-change-management` plus a sub-
    skill, *or* rename to `kiss-change-log` +
    `kiss-change-control` so the noun is more concrete.
  - `init` / `review` / `security-review` (the three
    bare-generic non-`kiss-` skills) → either
    (a) namespace-prefix them
    (`kiss-claude-md-init`, `kiss-pr-review`,
    `kiss-pr-security-review`) and ship them under the
    KISS manifest, or (b) leave them unprefixed because
    they are vendor-built-in re-exports (Claude Code's
    `/init`, `/review`, `/security-review`) that KISS
    just bundles for distribution — in which case they
    should be EXEMPTED from FR-015's bare-generic ban
    via an explicit allow-list.
- **Surface:**
  `docs/specs/agent-skills-system/spec.md`
  Naming Audit Appendix,
  `docs/decisions/ADR-019-agent-skill-naming-and-structure.md`.
- **Cross-link:** RDEBT-031 (spec/code divergence),
  TDEBT-029 (source-side rename pass).
- **Priority:** 🟡 Important.
- **Status:** Resolved (2026-04-26). All 4 decisions made:
  `kiss-adr` → `kiss-adr-author`;
  `kiss-change-register` → `kiss-change-log` (keep `kiss-change-control`);
  `init`/`review`/`security-review` → exempt as vendor built-ins;
  `claude-api`/`simplify` → exempt (not in source tree).

### RDEBT-030 — Cross-provider naming-rule conflicts (best-practice divergence)

- **Question:** The nine WebFetched provider docs
  (agentskills.io, Claude Code best-practices,
  Claude Code overview, Copilot, Cursor, OpenCode,
  Windsurf, Gemini CLI, Codex) on 2026-04-26 disagreed
  on three points the spec must pick a winner for:
  - **Reserved words.** Claude Code best-practices
    forbid `anthropic` and `claude` in the `name:`
    field; the other six providers and agentskills.io
    say nothing. ADR-019 sided with Claude Code (the
    strictest), banning the words for KISS skills
    universally — confirm this is acceptable, or
    relax the rule to "render the `name:` field
    differently per provider" (which contradicts
    FR-002 / ADR-005's three-format design).
  - **Naming style.** Claude Code best-practices
    prefer **gerund form** (verb + -ing); none of the
    other providers prescribe a style; the existing 49
    KISS skills use verb-then-noun. ADR-019 picked
    "verb-then-noun preferred, gerund accepted" —
    confirm or flip.
  - **Length cap.** agentskills.io / Claude Code /
    OpenCode pin `name` ≤ 64 chars; Cursor / Windsurf /
    Gemini / Codex / Copilot don't pin it. ADR-019
    adopts ≤ 64 universally — confirm.
- **Surface:**
  `docs/specs/agent-skills-system/spec.md`
  FR-011 / FR-012 / FR-013,
  `docs/decisions/ADR-019-agent-skill-naming-and-structure.md`.
- **Priority:** 🟢 Can wait.
- **Status:** Open.

### RDEBT-031 — Spec/code divergence: skill renames proposed in specs only

- **Question:** Per the brief's ground-rule "Never
  rename in source code … this pass is specs-only", the
  Naming Audit Appendix in
  `docs/specs/agent-skills-system/spec.md` PROPOSES
  renames for ≈ 15 skills (`kiss-acceptance`,
  `kiss-checklist`, `kiss-pm-planning`, `kiss-cicd`,
  `kiss-monitoring`, `kiss-deployment`, `kiss-infra`,
  `simplify`, `claude-api`, plus the
  `init`/`review`/`security-review` triple if the
  vendor-built-in interpretation is rejected). The
  actual folder names on disk under `agent-skills/`
  are unchanged. Until the source-side rename pass
  runs, the installer ships skills with the old names,
  the manifest tracks the old names, and any user who
  reads the spec will see a name mismatch with what
  `kiss init` actually installs. **Decider must
  schedule the rename pass and the migration story
  for users on existing installs.**
- **Surface:**
  `docs/specs/agent-skills-system/spec.md`
  Naming Audit Appendix,
  `docs/decisions/ADR-019-agent-skill-naming-and-structure.md`.
- **Cross-link:** TDEBT-029 (architecture mirror),
  RDEBT-029 (NEEDS-DECISION pre-requisites).
- **Priority:** 🔴 Blocking — every spec consumer
  reading the rename table will be confused until the
  source-side flip lands.
- **Status:** Resolved (2026-04-26). All 9 renames applied
  to source directories under `agent-skills/`. Naming Audit
  Appendix updated to show RENAMED status.

### RDEBT-032 — Subagent naming style: role-oriented vs action-oriented

- **Question:** ADR-020 §Naming style records that the
  seven supported providers DISAGREE on subagent naming
  style. Cursor and Copilot examples prefer
  **role-oriented** (`debugger`, `verifier`,
  `security-auditor`, `Plan`, `Researcher`); OpenCode
  and Codex prefer **action-oriented** (`code-reviewer`,
  `pr_explorer`, `docs_researcher`, `code_mapper`);
  Claude Code and Gemini CLI examples are mixed; Windsurf
  workflows are action-oriented by surface design. KISS's
  14 names are uniformly role-oriented (`architect`,
  `developer`, `tester`, …). ADR-020 DOES NOT flip the
  14 names but logs the question. Decider must pick one
  of:
  - **(a) KEEP role-oriented** — follows Cursor /
    Copilot preference; preserves every cross-spec
    reference and decision-log path; non-zero
    collision risk for single-token names
    (`architect`, `developer`, `tester`, `devops`).
  - **(b) FLIP to action-oriented** — follows OpenCode /
    Codex preference; e.g. `architect` →
    `design-architecture`, `developer` →
    `develop-features`, `tester` → `test-features`.
    Invalidates every cross-spec reference and every
    `agent-decisions/<agent-name>/` path; needs
    coordinated rename pass.
  - **(c) HYBRID** — keep role-oriented for the
    multi-faceted roles (`architect`, `business-analyst`,
    `product-owner`, `project-manager`, `scrum-master`,
    `ux-designer`) and flip the action-flavoured ones
    (`bug-fixer` already action-flavoured;
    `code-quality-reviewer` / `code-security-reviewer` /
    `technical-analyst` arguably action-flavoured
    already; `developer` / `tester` / `devops` are
    candidates for a flip).
- **Surface:** `docs/specs/subagent-system/spec.md`
  Naming Audit Appendix (rows 1, 6, 7, 13);
  `docs/decisions/ADR-020-subagent-naming-and-structure.md`
  §Naming style.
- **Cross-link:** RDEBT-033 (sibling question —
  prefix + collision), TDEBT-030 (source-side rename
  pass).
- **Priority:** 🟢 Can wait.
- **Status:** Open.

### RDEBT-033 — `kiss-` prefix on subagents + built-in agent collision risk

- **Question:** ADR-020 §9 records that subagent names
  do **NOT** carry a `kiss-` prefix today, unlike the
  ADR-019 `kiss-*` skill prefix. The reasoning:
  per-provider agent folders (`.<provider>/agents/`)
  are project-managed by the user, so the prefix
  doesn't protect installer manifests the way it does
  for skills. Four of the 14 names are single English
  words (`architect`, `developer`, `tester`, `devops`)
  that carry built-in collision risk. Codex reserves
  `default`, `worker`, `explorer` (no current KISS
  collision); the other six providers don't publish a
  reserved-words list but may add one. Decider must
  pick one of:
  - **(a) KEEP unprefixed** — current state; relies on
    the user's empty `.<provider>/agents/` folder at
    `kiss init` time + per-provider manifest
    discipline.
  - **(b) PREFIX all 14** with `kiss-` for symmetry
    with skills; impacts every cross-spec reference
    and decision-log path.
  - **(c) PREFIX only the four single-token names**
    (`architect`, `developer`, `tester`, `devops`) →
    `kiss-architect`, `kiss-developer`, `kiss-tester`,
    `kiss-devops`. Mixed-prefix style is the cost.
- **Surface:** `docs/specs/subagent-system/spec.md`
  FR-018 + Naming Audit Appendix (rows 1, 6, 7, 13);
  `docs/decisions/ADR-020-subagent-naming-and-structure.md`
  §9.
- **Cross-link:** RDEBT-032 (sibling style question),
  TDEBT-030 (source-side rename pass).
- **Priority:** 🟡 Important.
- **Status:** Open.

### RDEBT-034 — Subagent description tightening pass

- **Question:** Per ADR-020 §3 / FR-015, every
  role-agent `description:` MUST front-load the
  trigger phrase, state what the agent does AND
  when to invoke it, and disambiguate from sibling
  agents in the first sentence. Hard cap: ≤ 1024
  chars (passes today for all 14); recommended
  length: 200–600 chars. Current 14 descriptions
  are 200–500 words each (≈ 1200–3000 chars before
  truncation). Cursor explicitly warns "vague
  descriptions"; Claude Code's example
  descriptions for `code-reviewer`, `debugger`,
  `data-scientist` are one-to-three sentences,
  ≈ 30–80 words. The siblings most needing
  disambiguation are:
  - `tester` ↔ `test-architect` (execution vs
    strategy);
  - `code-quality-reviewer` ↔ `code-security-reviewer`
    (maintainability vs CVE);
  - `product-owner` ↔ `project-manager` ↔
    `scrum-master` (backlog vs plan vs ceremonies).
  Decider must approve a tightening pass that
  rewrites all 14 descriptions to the
  recommended length, front-loading the
  differentiator. Spec-only edit; the on-disk
  prompt files in `subagents/` change in the
  source-side pass per RDEBT-035 / TDEBT-030.
- **Surface:** `docs/specs/subagent-system/spec.md`
  FR-015 + Naming Audit Appendix (every row's
  RDEBT-034 column);
  `docs/decisions/ADR-020-subagent-naming-and-structure.md`
  §3.
- **Cross-link:** RDEBT-035 (spec/code divergence),
  TDEBT-030 (source-side rewrite pass).
- **Priority:** 🟡 Important.
- **Status:** Open.

### RDEBT-035 — Spec/code divergence: subagent renames + per-AI rendering proposed in specs only

- **Question:** Per the brief's ground-rule "Never
  rename in source code … this pass is specs-only",
  ADR-020 + the Naming Audit Appendix in
  `docs/specs/subagent-system/spec.md` PROPOSE rules
  (kebab-case enforcement, single-purpose, two-mode
  UX preservation, AI-only scope preservation,
  per-AI frontmatter rendering, no `kiss-` prefix)
  and a per-subagent verdict table (10 KEEP, 0
  RENAME, 4 NEEDS-DECISION) but NEITHER renames any
  on-disk file under `subagents/` NOR teaches
  `installer.py:429-494` (`install_custom_agents`)
  the per-provider rendering branch table from
  ADR-020 §5 / FR-014. Until the source-side pass
  runs:
  - the bundled prompts ship with Claude Code-shaped
    frontmatter only;
  - Windsurf installs receive YAML frontmatter that
    Cascade ignores (and which counts toward the
    12 000-char cap);
  - OpenCode installs lack `mode: subagent` and may
    surface as `all`-mode primary agents;
  - Codex receives Markdown rather than rendered
    TOML;
  - Copilot installs use `<role>.md` rather than
    `<role>.agent.md`.
  Whether any of the above is actually broken on
  the current installer is **(unverified — confirm)**
  per RDEBT-027. Decider must schedule the source-
  side pass and the migration story for users on
  existing installs.
- **Surface:**
  `docs/specs/subagent-system/spec.md` FR-014 +
  Naming Audit Appendix;
  `docs/decisions/ADR-020-subagent-naming-and-structure.md`
  Consequences.
- **Cross-link:** TDEBT-030 (architecture mirror),
  RDEBT-027 (installer compliance verification),
  RDEBT-032 / RDEBT-033 / RDEBT-034 (rename + style
  + description prerequisites).
- **Priority:** 🔴 Blocking — every spec consumer
  reading the rule table will be confused until the
  source-side flip lands.
- **Status:** Open.
