# Architecture / Technical Debt Register

> Maintained by the `architect` agent (and other role agents).
> Each entry has a unique `TDEBT-NNN` ID, a one-line summary, the
> owning question still open, the artefact / source it surfaced
> in, and a status. New entries append; entries close by editing
> their **Status**.
>
> Generated 2026-04-26 by `architect` (auto mode), seeded from
> `docs/architecture/extracted.md` and the re-design pass.

## Status legend

- **Open** — needs a human decision.
- **Resolved** — the question is answered; the resolution is
  recorded in an ADR or in the resolving artefact.
- **Carried** — known and documented, no fix planned this cycle.

## Entries

### TDEBT-001 — Promote CADR-001…012 to accepted ADRs

- **Question:** Each of ADR-001 … ADR-012 was promoted from a
  candidate ADR in `docs/architecture/extracted.md` §7. They are
  in `Proposed` status with **Decider: TBD — confirm**. Who is
  the decider, and which can be flipped to `Accepted`?
- **Surface:** `docs/decisions/ADR-001-cli-framework-typer-click.md`
  through `docs/decisions/ADR-012-two-mode-ux-interactive-and-auto.md`.
- **Status:** Open.

### TDEBT-002 — Wire `_integrity.verify_asset_integrity` into the runtime path

- **Question:** ADR-007 commits to verifying
  `core_pack/sha256sums.txt` at the start of every `kiss init` /
  `kiss upgrade`. Today the function exists
  (`src/kiss_cli/_integrity.py:24-79`) but its production call
  site was not located by the technical-analyst
  (ANALYSISDEBT-002). Who is the decider that approves wiring it
  in, and which subcommands trigger the check?
- **Surface:** `docs/decisions/ADR-007-asset-integrity-via-sha256sums.md`.
- **Status:** Open.

### TDEBT-003 — Decider for ADR-013 (`extensions.py` decomposition)

- **Question:** Decompose `src/kiss_cli/extensions.py` into the
  `extensions/` package per ADR-013. Decider TBD; PR-A through
  PR-F sequencing approved by whom?
- **Surface:** `docs/decisions/ADR-013-decompose-extensions-py.md`.
- **Status:** Open.

### TDEBT-004 — Decider for ADR-014 (`presets.py` decomposition)

- **Question:** Decompose `src/kiss_cli/presets.py` into the
  `presets/` package per ADR-014. Decider TBD.
- **Surface:** `docs/decisions/ADR-014-decompose-presets-py.md`.
- **Status:** Open.

### TDEBT-005 — Decider for ADR-015 (parity-test commitment)

- **Question:** Promote Bash/PowerShell parity to an
  architectural invariant and add a mechanical parity test.
  Decider TBD.
- **Surface:** `docs/decisions/ADR-015-bash-powershell-parity-as-architectural-invariant.md`.
- **Status:** Open.

### TDEBT-006 — Decider for ADR-016 (`[tool.ruff]` configuration)

- **Question:** Adopt explicit Ruff lint + format configuration
  in `pyproject.toml`. Decider TBD; final `select` rule list to
  be approved by whom?
- **Surface:** `docs/decisions/ADR-016-adopt-tool-ruff-config-for-lint-and-format.md`,
  `docs/research/python-lint-format-toolchain.md`.
- **Status:** Open.

### TDEBT-007 — Decider for ADR-017 (offline-runtime boundary tests)

- **Question:** Expand `tests/test_offline.py` to cover every
  CLI subcommand. Decider TBD; fixture portability across
  Linux + Windows confirmed by whom?
- **Surface:** `docs/decisions/ADR-017-enforce-offline-runtime-via-boundary-tests.md`.
- **Status:** Open.

### TDEBT-008 — Resolve `Generic` 13-vs-14 integration count discrepancy

- **Question:** `integrations/__init__.py:50-81` registers 13
  integrations; `CLAUDE.md` says "14 AI providers". Is the user
  count meant to include `Generic` (BYO) as a "provider" in
  user-facing materials? (Originally
  ANALYSISDEBT-005.)
- **Surface:** `docs/architecture/intake.md` §5.
- **Status:** Open.

### TDEBT-009 — Confirm PyPI publication intent

- **Question:** Is KISS published (or planned to be published) to
  PyPI? Today only GitHub Releases artefacts are wired
  (`.github/workflows/release.yml:128-138`). ADR-008 commits to
  *not* auto-publishing on tag, but does not commit to *whether*
  PyPI is wired manually. (Originally ANALYSISDEBT-004.)
- **Surface:** `docs/architecture/intake.md` §5,
  `docs/decisions/ADR-008-tag-triggered-releases-no-auto-pypi-push.md`.
- **Status:** Open.

### TDEBT-010 — `dispatch_command` call-site enumeration

- **Question:** `IntegrationBase.dispatch_command`
  (`integrations/base.py:147-225`) is currently used by
  workflow `command` steps. The technical-analyst could not
  confirm the full set of call sites. (Originally
  ANALYSISDEBT-003.)
- **Surface:** `docs/architecture/extracted.md` §2 C5.
- **Status:** Open.

### TDEBT-011 — `pydeps` / `import-graph` confirmation of fan-in counts

- **Question:** Top-25 fan-in counts in
  `docs/analysis/dependencies.md` §2 were derived by
  text-grep; some inside-function imports may be missed. Hardening
  the numbers requires running `pydeps` or similar. (Originally
  ANALYSISDEBT-006.)
- **Surface:** `docs/analysis/dependencies.md` §2.
- **Status:** Open.

### TDEBT-012 — Confirm no real circular imports in test run

- **Question:** Several lazy-import workarounds exist
  (`installer.py:39-45`, `agents.py:19-29`,
  `workflows/engine.py:43-50`); the analyst inferred no real
  cycles but did not run the suite. (Originally ANALYSISDEBT-007.)
- **Surface:** `docs/analysis/dependencies.md` §3.
- **Status:** Open.

### TDEBT-013 — Architecture intake decider

- **Question:** Who is the decider that accepts
  `docs/architecture/intake.md` and the C4 diagrams as the
  current architectural truth?
- **Surface:** `docs/architecture/intake.md`,
  `c4-context.md`, `c4-container.md`, `c4-component.md`.
- **Status:** Open.

### TDEBT-014 — macOS coverage in CI test matrix

- **Question:** `CLAUDE.md` claims macOS support; the CI matrix
  (`.github/workflows/test.yml:30-55`) only runs `ubuntu-latest`
  and `windows-latest`. Should `macos-latest` be added, or the
  claim retracted?
- **Surface:** `docs/architecture/intake.md` §2.
- **Status:** Open.

### TDEBT-015 — Coverage threshold pin

- **Question:** Quality Gates require ≥ 80% line coverage on
  changed files; no threshold is configured in `pyproject.toml`
  (`docs/analysis/codebase-scan.md` §5). Wire
  `--cov-fail-under` to which value? (Likely 80, but
  per-changed-file vs. project-wide differs.)
- **Surface:** `docs/architecture/intake.md` §2.
- **Status:** Open. Sequenced after ADR-016 lands.

### TDEBT-016 — Confirm team size band

- **Question:** Architecture intake §3 inferred "single-developer /
  very small team" from CLAUDE.md framing; explicit confirmation
  helps right-size future hiring / process changes.
- **Surface:** `docs/architecture/intake.md` §3.
- **Status:** Open.

### TDEBT-017 — Performance budget for `kiss init`

- **Question:** Should there be a wall-clock SLO for `kiss init`
  on a developer laptop? (Currently no budget; subjective
  "should complete in seconds".)
- **Surface:** `docs/architecture/intake.md` §4.
- **Status:** Open.

### TDEBT-018 — PyPI publication strategy (manual workflow)

- **Question:** When PyPI is wired, what is the trigger? Manual
  `gh workflow run` per release? OIDC trusted publisher? Per
  ADR-008 it must NOT be tag-auto.
- **Surface:** `docs/architecture/intake.md` §5,
  `docs/decisions/ADR-008-tag-triggered-releases-no-auto-pypi-push.md`.
- **Status:** Open.

### TDEBT-019 — Final installable name on PyPI

- **Question:** What's the public name? `kiss`, `kiss-u`,
  `kiss-cli`, … `pyproject.toml:2` reads `name = "kiss"` but the
  GitHub repo is `kiss-u`. Naming impacts every install
  instruction in `docs/installation.md`.
- **Surface:** `docs/architecture/intake.md` §6.
- **Status:** Open.

### TDEBT-020 — Two `CommandRegistrar` classes (name collision)

- **Question:** `kiss_cli.agents.CommandRegistrar` and the local
  `CommandRegistrar` defined inside `extensions.py:1439` are
  unrelated classes that share a name. ADR-013 moves the second
  into `extensions/frontmatter.py` but does not rename it.
  Rename to `FrontmatterCodec` (suggested) or keep?
- **Surface:** `docs/architecture/intake.md` §9,
  `docs/decisions/ADR-013-decompose-extensions-py.md`.
- **Status:** Open.

### TDEBT-021 — Mechanical Bash/PowerShell parity test

- **Question:** ADR-015 commits to a parity test; the test does
  not yet exist. Decider for the test scope (file presence only?
  flag-name check? exit-code check?) and the test framework.
- **Surface:** `docs/decisions/ADR-015-bash-powershell-parity-as-architectural-invariant.md`.
- **Status:** Open.

### TDEBT-022 — Decompose `integrations/base.py` (1,374 LOC)

- **Question:** Next file over the size limit after `extensions.py`
  and `presets.py`. ADR-005 records the three-class design (Markdown /
  Toml / Skills) but the implementation file is monolithic.
  Schedule a follow-up ADR after ADR-013 / ADR-014 land?
- **Surface:** `docs/architecture/intake.md` §8,
  `docs/decisions/ADR-005-three-output-formats-for-integrations.md`.
- **Status:** Carried.

### TDEBT-023 — Benchmark cost of `verify_asset_integrity` at init

- **Question:** ADR-007 estimates ~100 ms per `kiss init` for the
  hash check on an SSD; this is unverified. Measure on the actual
  bundled tree before committing the wiring.
- **Surface:** `docs/decisions/ADR-007-asset-integrity-via-sha256sums.md`.
- **Status:** Open.

### TDEBT-024 — Drift check between `_register_builtins` and `integrations/catalog.json`

- **Question:** ADR-009 notes the two lists are duplicated and
  drift is possible. Add a test that diffs them?
- **Surface:** `docs/decisions/ADR-009-static-integration-registry.md`.
- **Status:** Open.

### TDEBT-025 — Pin Ruff minor version

- **Question:** ADR-016's recommendation is to pin Ruff (e.g.
  `ruff>=0.13,<0.16`). Confirm the active range at PR time —
  Ruff is still in 0.x and minor-bumps can change rule defaults.
- **Surface:** `docs/research/python-lint-format-toolchain.md`,
  `docs/decisions/ADR-016-adopt-tool-ruff-config-for-lint-and-format.md`.
- **Status:** Open.

### TDEBT-026 — Decide `line-length` for Ruff format

- **Question:** Default 88 (Black) vs. 100 (Ruff format common
  alternative) vs. the codebase's current de-facto. Measure
  before pinning to keep the first format-only PR small.
- **Surface:** `docs/research/python-lint-format-toolchain.md`.
- **Status:** Open.

### TDEBT-027 — Per-file lint-ignore allowlist for legacy modules

- **Question:** ADR-016's first lint pass will surface
  pre-existing violations in `extensions.py`, `presets.py`,
  `integrations/base.py`. Enumerate them as
  per-file-ignores so the first PR passes; remove as ADR-013 /
  ADR-014 / TDEBT-022 PRs land.
- **Surface:** `docs/research/python-lint-format-toolchain.md`.
- **Status:** Open.

### TDEBT-028 — Spec narrowed to 7 AIs but code still ships 13

- **Question:** ADR-018 (proposed 2026-04-26) narrows the
  supported AI integrations to seven (Claude Code, GitHub
  Copilot, Cursor Agent, OpenCode, Windsurf, Gemini CLI,
  Codex) per `docs/AI-urls.md`. The source code at
  `src/kiss_cli/integrations/__init__.py:14-84` and
  `integrations/catalog.json` still register 13. The
  source-code narrowing pass — remove the six unsupported
  packages (`agy`, `auggie`, `kilocode`, `kiro_cli`,
  `tabnine`, `generic`), update the catalog JSON, update
  `tests/test_init_multi.py` and any per-integration test —
  is deferred. Decider for the cut-over point: **TBD —
  confirm**.
- **Surface:** `docs/architecture/extracted.md` §4,
  `docs/architecture/intake.md` §5,
  `docs/specs/integration-system/spec.md` FR-016 / FR-017,
  `docs/decisions/ADR-018-narrow-integration-scope-to-seven-ais.md`.
- **Cross-link:** RDEBT-024 (spec-side mirror).
- **Status:** Open.

### TDEBT-029 — Source-side rename pass for ADR-019 (agent-skill naming + structure)

- **Question:** ADR-019 (`Proposed`, 2026-04-26) and the
  Naming Audit Appendix in
  `docs/specs/agent-skills-system/spec.md` adopt provider
  best-practice naming + structure rules and PROPOSE
  ≈ 15 skill renames. The actual folder names on disk
  under `agent-skills/` are unchanged per the docs-only
  ground-rule of the audit pass. The eventual source-side
  pass must:
  1. Rename the affected folders under `agent-skills/`
     (e.g. `kiss-cicd/` → `kiss-cicd-pipeline/`,
     `simplify/` → `kiss-simplify-code/`,
     `claude-api/` → `kiss-anthropic-sdk/`, etc.).
  2. Update the in-folder `kiss-<name>.md` filenames to
     match the new directory names.
  3. Update the `name:` frontmatter in each renamed
     `SKILL.md`.
  4. Update every reference in the registry / installer:
     `src/kiss_cli/agents.py` (`CommandRegistrar`),
     `src/kiss_cli/skill_assets.py`,
     `src/kiss_cli/integrations/__init__.py`,
     `src/kiss_cli/integrations/<integration>/__init__.py`,
     `tests/test_agent_skills_compliance.py`,
     `tests/test_init_multi.py`, every fixture under
     `tests/fixtures/`, every cross-referenced
     `extensions/<ext>/extension.yml` /
     `presets/<preset>/preset.yml`.
  5. Update the manifest-migration logic so users on
     existing installs (which carry the old names in
     their per-integration manifest) get the renamed
     bundles re-deployed in `kiss init --here --force`
     and the old folders cleaned up.
  6. Update CI gate `.github/workflows/validate-skills.yml`
     and the agentskills.io compliance test to enforce
     the new rules (FR-011 … FR-017).
- **Surface:**
  `docs/decisions/ADR-019-agent-skill-naming-and-structure.md`,
  `docs/specs/agent-skills-system/spec.md`
  Naming Audit Appendix,
  `agent-skills/` (≈ 15 folder renames pending),
  `src/kiss_cli/agents.py`,
  `src/kiss_cli/skill_assets.py`,
  `src/kiss_cli/integrations/`,
  `tests/test_agent_skills_compliance.py`,
  `tests/test_init_multi.py`.
- **Cross-link:** RDEBT-029 (NEEDS-DECISION items —
  must resolve before the source-side pass), RDEBT-031
  (spec-side mirror), ADR-019.
- **Status:** Open.

### TDEBT-030 — Source-side rename + per-AI rendering pass for ADR-020 (subagent naming + structure)

- **Question:** ADR-020 (`Proposed`, 2026-04-26) and
  the Naming Audit Appendix in
  `docs/specs/subagent-system/spec.md` adopt provider
  best-practice naming + structure rules for the 14
  bundled role-agent prompts and PROPOSE a per-AI
  rendering branch table (Claude Code verbatim,
  Copilot `.agent.md`, Cursor frontmatter filter,
  OpenCode `mode: subagent`, Windsurf YAML strip +
  12 000-char cap, Gemini frontmatter filter, Codex
  TOML render). The actual installer source at
  `src/kiss_cli/installer.py:429-494`
  (`install_custom_agents`) and the per-integration
  classes do **NOT** perform per-provider rendering
  today — every supported AI receives the bundled
  Claude Code-shaped Markdown verbatim. The eventual
  source-side pass must:
  1. Add per-provider rendering branches to
     `install_custom_agents` for each of the seven
     supported AIs:
     - Claude Code → verbatim copy (current
       behaviour).
     - Copilot → rename `<role>.md` to
       `<role>.agent.md` on write; filter
       frontmatter to Copilot-supported keys.
     - Cursor → filter frontmatter to Cursor-
       supported keys (`name`, `description`,
       `model`, `readonly`, `is_background`); add
       `readonly: true` for review-flavoured agents
       (`code-quality-reviewer`,
       `code-security-reviewer`,
       `technical-analyst`).
     - OpenCode → inject `mode: subagent` into
       frontmatter; filter to OpenCode-supported
       keys.
     - Windsurf → STRIP YAML frontmatter; cap output
       at 12 000 chars (preserve two-mode UX +
       AI-only scope + decision-log clauses per
       FR-017); install at
       `.windsurf/workflows/<role>.md`.
     - Gemini CLI → filter frontmatter to Gemini-
       supported keys.
     - Codex → render Markdown to TOML: required
       keys `name`, `description`,
       `developer_instructions` (Markdown body);
       optional `model`, `model_reasoning_effort`,
       `sandbox_mode`, `mcp_servers`. Install at
       `.codex/agents/<role>.toml`.
  2. Update each per-integration class
     (`src/kiss_cli/integrations/<integration>/__init__.py`)
     with the agent-folder path + file-extension +
     rendering hint.
  3. If RDEBT-032 (role-oriented vs action-oriented)
     and / or RDEBT-033 (`kiss-` prefix on subagents)
     resolves "RENAME", rename the affected files
     under `subagents/`, update `name:` in every
     renamed prompt, update every cross-spec
     reference to the role names, update the
     decision-log path
     (`{paths.docs}/agent-decisions/<agent-name>/`),
     and migrate user-side decision logs that already
     contain entries under the old role name.
  4. If RDEBT-034 (description tightening) resolves
     "TIGHTEN", rewrite the 14 `description:` blocks
     to 200–600 chars front-loading the trigger
     phrase + sibling-disambiguation.
  5. Add `tests/test_subagent_compliance.py`
     (TDEBT-030) that checks: filename matches
     `^[a-z0-9]+(-[a-z0-9]+)*$`; `name:` equals
     basename; `description:` ≤ 1024 chars;
     two-mode UX clause present; AI-only scope
     clause present; decision-log path present;
     per-provider rendering deterministic
     (NFR-006).
  6. Update `tests/test_init_multi.py` fixtures to
     verify the per-AI rendering branches produce
     the expected per-provider files.
  7. Update the manifest hashing
     (`src/kiss_cli/integrations/manifest.py`)
     to account for per-provider rendering being
     deterministic — same wheel + same context.yml
     - same provider produces identical SHA-256s.
- **Surface:**
  `docs/decisions/ADR-020-subagent-naming-and-structure.md`,
  `docs/specs/subagent-system/spec.md`
  Naming Audit Appendix + FR-012…FR-018,
  `subagents/` (14 prompts; rename optional per
  RDEBT-032 / RDEBT-033),
  `src/kiss_cli/installer.py:429-494`,
  `src/kiss_cli/integrations/<integration>/__init__.py`
  (seven providers),
  `src/kiss_cli/integrations/manifest.py`,
  `tests/test_init_multi.py`,
  `tests/test_subagent_compliance.py` (new).
- **Cross-link:** RDEBT-027 (installer compliance
  verification — answer the "today's behaviour"
  question first), RDEBT-032 / RDEBT-033 (NEEDS-
  DECISION items — must resolve before any rename),
  RDEBT-034 (description tightening), RDEBT-035
  (spec-side mirror), ADR-020, ADR-019 (sibling).
- **Status:** Open.
