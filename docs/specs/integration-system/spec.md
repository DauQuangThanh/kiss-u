# Feature Specification: integration-system

**Feature Slug**: `integration-system`
**Created**: 2026-04-26
**Updated**: 2026-04-26 (narrowed supported AIs from 13 → 7; source-code narrowing completed)
**Status**: Draft (reverse-engineered)
**Mode**: auto
**Input**: `integrations/__init__.py:14-84`,
`integrations/base.py:1-1374`,
`integrations/manifest.py:50-265`,
`integrations/catalog.py:1-511`,
`cli/check.py:1-639`,
`docs/architecture/extracted.md` §4,
`docs/AI-urls.md` (authoritative supported-AI list),
`docs/research/ai-providers-2026-04-26.md`.

## Problem Statement

kiss exists to bridge a single SDD project tree into the AI
provider tools the user actually uses. As of 2026-04-26 the
supported list has been narrowed to **seven AIs** (per the
authoritative `docs/AI-urls.md`):

1. **Claude Code** (`claude`).
2. **GitHub Copilot** (`copilot`).
3. **Cursor Agent** (`cursor_agent`).
4. **OpenCode** (`opencode`).
5. **Windsurf** (`windsurf`).
6. **Gemini CLI** (`gemini`).
7. **Codex** (`codex`).

Each provider has its own folder convention, its own command
file format (Markdown `SKILL.md` folder, Markdown command, TOML
in Codex's case), its own context-file convention (`CLAUDE.md`,
`AGENTS.md`, or `GEMINI.md`), and its own subagent surface
(see `docs/specs/subagent-system/spec.md`).

Without a shared abstraction, every new provider would mean
copying and tailoring the entire installer flow. The integration
system gives kiss a single contract — `IntegrationBase` and its
three subtypes (`MarkdownIntegration`, `TomlIntegration`,
`SkillsIntegration`) — so:

- adding a new provider is one subclass + a registry line;
- every install is hashed in a per-integration manifest, so
  uninstall and upgrade are diff-aware;
- the CLI commands (`kiss integration list / install /
  uninstall / switch / upgrade` plus `kiss check integrations`)
  work uniformly across all seven providers.

> **Removed (2026-04-26):** `kiro-cli`, `auggie`,
> `tabnine`, `kilocode`, `agy` (Antigravity), `generic`. These
> integrations were removed from the source code as of
> 2026-04-26. RDEBT-024 / TDEBT-028 are resolved.

Source evidence: the source code registers exactly 7
integration packages under `src/kiss_cli/integrations/`;
the abstract base
(`integrations/base.py:56-1374`); the registry
(`integrations/__init__.py:14-84`); the manifest
(`integrations/manifest.py:50-265`); the integrity helper
(`_integrity.py:24-79` — defined but currently un-wired,
RDEBT-003 / TDEBT-002); per-AI facts in
`docs/research/ai-providers-2026-04-26.md`.

## Clarifications

### Session 2026-04-26

- Q: When `dispatch_command` times out (default 600s), what should happen to the child process? → A: Kill the process (SIGTERM → 5s grace → SIGKILL) and exit with code `124` plus a timeout message. Each workflow step uses the default; per-step override is not supported.
- Q: When multiple integrations are installed, should they share cross-agent folders like `.agents/skills/`? → A: No. Each integration MUST write only to its own primary folder (e.g. Claude → `.claude/skills/`, Copilot → `.github/skills/`, Cursor → `.cursor/skills/`). The `.agents/skills/` folder is a user-managed fallback that AI tools can read from but kiss does not populate.
- Q: When `kiss check` finds problems, should it stop at the first or show everything? → A: Show all problems found across all sub-checks in one pass, with a suggested fix command or action for each finding.
- Q: `.kiss/integration.json` has both a singular `integration` field and a plural `integrations` list — which should be kept for multi-integration? → A: Drop the singular `integration` field; keep only `integrations: [list]`. Code that reads the singular field must be updated to read the list instead.
- Q: With multiple integrations installed, should `kiss integration upgrade` refresh all at once or one at a time? → A: One at a time by name (`kiss integration upgrade claude`), with an `--all` flag that upgrades every installed integration in sequence. Each upgrade is isolated — if one fails, the rest are not attempted.

## User Scenarios & Testing

### User Story 1 — Add a new AI provider (within the supported set) (Priority: P1)

As a kiss contributor adding support for one of the seven
listed AI providers, I want to subclass one of the three
integration base classes and add a single line in
`_register_builtins()` — and have the new provider work in every
existing CLI command (`list`, `install`, `uninstall`, `switch`,
`upgrade`, plus `kiss init` multi-select) with zero changes to
the CLI layer.

**Why this priority**: The system's headline value — pluggable
multi-AI without a forking blast radius. (Note: the eligibility
gate is now ADR-018 — only the seven AIs in
`docs/AI-urls.md` may be added.)

**Independent test**: Subclass `SkillsIntegration` for one of
the seven supported AIs; add it to the registry; run
`kiss integration list` and `kiss integration install <key>`;
confirm both work without other code changes.

**Acceptance Scenarios**:

1. **Given** a new integration class registered in
   `INTEGRATION_REGISTRY` via `_register_builtins`, **When**
   the user runs `kiss integration list`, **Then** the new
   integration appears with its `Name` and `CLI Required`
   metadata (`integrations/__init__.py:40-81`).
2. **Given** the same new integration, **When** the user runs
   `kiss integration install <new>`, **Then** the install flow
   succeeds with no CLI-layer changes — the base class drives
   `setup` (`integrations/base.py:771-817`).

### User Story 2 — Markdown vs. TOML vs. Skills format (Priority: P1)

As a contributor implementing a new provider, I want a clear
choice between the three output formats so I can pick the one
that matches the provider's convention:

- `MarkdownIntegration` — provider expects standalone
  Markdown command files.
- `TomlIntegration` — provider expects `.toml` files
  (relevant to Codex subagents per
  `docs/research/ai-providers-2026-04-26.md`).
- `SkillsIntegration` — provider expects a folder per skill
  with a `SKILL.md` plus bundled `scripts/` and `templates/`
  (the agentskills.io convention; relevant to all seven
  supported AIs for the *skills* surface).

**Acceptance Scenarios**:

1. **Given** a `MarkdownIntegration` subclass, **When** the
   user runs `kiss init --integration <md-key>`, **Then**
   command files land as `*.md` in the integration's folder
   (`integrations/base.py:892-955`).
2. **Given** a `TomlIntegration` subclass, **When** the user
   runs init, **Then** command files land as `*.toml`
   (`integrations/base.py:963-…`).
3. **Given** a `SkillsIntegration` subclass, **When** the
   user runs init, **Then** each command lands in a folder
   `kiss-<name>/SKILL.md` with bundled `scripts/` and
   `templates/` (`skill_assets.py:79-127`).

### User Story 3 — File-by-file SHA-256 manifest (Priority: P1)

As an end user, I want every file kiss writes for an
integration to be recorded in a manifest with its SHA-256, so
that uninstall and upgrade can detect the files I have
modified and never silently overwrite or delete them.

**Acceptance Scenarios**:

1. **Given** an integration is installed, **When** the install
   completes, **Then**
   `.kiss/integrations/<key>.manifest.json` exists with
   `{key, version, installed_at, files: {rel_path: sha256}}`
   (`integrations/manifest.py:50-265`).
2. **Given** the user has modified a file post-install,
   **When** they run `kiss integration upgrade <key>`,
   **Then** the modified file is listed and the upgrade is
   blocked unless `--force` is supplied
   (`cli/integration.py:528-535`).
3. **Given** the user runs `kiss integration uninstall <key>`,
   **When** modified files exist, **Then** they are preserved
   by default and removed only with `--force`
   (`cli/integration.py:264,329-335`).

### User Story 4 — Asset integrity is verifiable (Priority: P2)

As a security-conscious user, I want kiss to be able to verify
that the bundled assets it ships have not been tampered with —
the wheel embeds `core_pack/sha256sums.txt` at build time and
`_integrity.verify_asset_integrity` can validate it.

**Acceptance Scenarios**:

1. **Given** the bundled assets are intact, **When** kiss
   reads them, **Then** `verify_asset_integrity` (when
   invoked) returns success
   (`_integrity.py:24-79`).
2. **Given** a tampered asset, **When** verification runs,
   **Then** an `AssetCorruptionError` is raised
   (`_integrity.py:11-21`).

> **Note**: As of 2026-04-26, the verification is implemented
> but no production caller invokes it during normal `kiss init`
> / `kiss upgrade`. ADR-007 commits to wiring it; the work is
> tracked as **RDEBT-003** / TDEBT-002.

### User Story 5 — `kiss check` diagnostics (Priority: P2)

> **Extracted to standalone spec**: See
> `docs/specs/kiss-check/spec.md` for the full `kiss check`
> feature specification (US-1 through US-5, FR-001 through
> FR-009). This user story is retained as a cross-reference.

### User Story 6 — Static, drift-free integration registry of exactly seven AIs (Priority: P3)

As a kiss maintainer, I want the integration registry to be
inline in `_register_builtins()` so it is impossible to install
a "rogue" integration via plugin discovery, and I want a test
that catches drift between the registry and
`integrations/catalog.json` (TDEBT-024). Per ADR-018, the
registry MUST contain exactly the seven supported AIs:
`claude`, `copilot`, `cursor_agent`, `opencode`, `windsurf`,
`gemini`, `codex`.

**Acceptance Scenarios**:

1. **Given** the codebase, **When** importing
   `kiss_cli.integrations`, **Then**
   `INTEGRATION_REGISTRY` is populated by
   `_register_builtins()` and contains exactly the seven
   built-ins listed above (per ADR-018).
2. **Given** drift between
   `_register_builtins` and
   `integrations/catalog.json`, **When** the proposed drift-
   check test runs (TDEBT-024), **Then** it fails — *not yet
   implemented*.

### Edge Cases

- **Unknown integration key** at install time:
  exits with code `1` (`cli/integration.py:199-204`). This
  includes any of the six removed keys (`kiro-cli`, `auggie`,
  `tabnine`, `kilocode`, `agy`, `generic` — removed
  2026-04-26).
- **Two integrations writing to the same path**: not possible
  because each integration writes only to its own primary
  directory tree (FR-018). Cross-agent fallback folders like
  `.agents/skills/` are not populated by kiss.
  Multi-integration is supported both at init and post-init.
- **Tampered bundled asset**: detectable by
  `verify_asset_integrity`; not currently invoked at runtime
  (RDEBT-003).
- **External AI CLI missing**: `kiss init`'s precheck warns;
  `--ignore-agent-tools` skips. `kiss check` does not require
  the CLI to be present.
- **`dispatch_command` keyboard interrupt** during streamed
  output: exits with code `130`
  (`integrations/base.py:202-207`).
- **Removed integration still on disk** (e.g. user upgrades
  through the source-code narrowing pass): manifest-driven
  uninstall preserves user-modified files; flow per
  `kiss-uninstall/spec.md`.
- **Catalog network access** for community integrations: see
  **RDEBT-023**.
- **Catalog trust model**: see **RDEBT-022**.
- **subagents target folder per integration**: behaviour
  depends on whether the integration class defines an
  `agents_folder` — see `docs/specs/subagent-system/spec.md`
  and **RDEBT-027** (supersedes RDEBT-020 for the seven
  supported AIs).

## Requirements

### Functional Requirements

- **FR-001**: The system MUST expose a static
  `INTEGRATION_REGISTRY: dict[str, IntegrationBase]`
  populated by `_register_builtins()`
  (`integrations/__init__.py:14-84`).
- **FR-002**: The system MUST expose `get_integration(key)
  -> IntegrationBase | None`
  (`integrations/__init__.py:32-34`).
- **FR-003**: Every integration MUST inherit from one of:
  `MarkdownIntegration`, `TomlIntegration`, or
  `SkillsIntegration` (which all extend `IntegrationBase`)
  (ADR-005, `integrations/base.py:56,865+`).
- **FR-004**: Every integration's `setup` MUST: copy / render
  command files, copy bundled skill scripts and templates
  via `bundle_skill_assets`, hash every file written,
  and append entries to the supplied
  `IntegrationManifest` (`integrations/base.py:771-817`,
  `skill_assets.py:79-127`,
  `integrations/manifest.py:50-265`).
- **FR-005**: Every integration's `teardown(...,
  force=False)` MUST iterate the manifest and remove each
  file unless `force=False` AND the on-disk SHA differs from
  the manifest record (`integrations/base.py:819-835`).
- **FR-006**: `IntegrationBase.dispatch_command(name, args,
  *, project_root, model, timeout=600, stream=True)` MUST
  invoke the integration's external CLI as a subprocess
  with the rendered slash command; on `KeyboardInterrupt`,
  the wrapper MUST exit with code `130`
  (`integrations/base.py:147-225`). On timeout expiry, the
  wrapper MUST send `SIGTERM` to the child process, wait up
  to 5 seconds for graceful shutdown, then `SIGKILL` if
  still running; the wrapper MUST exit with code `124`
  (matching GNU `timeout` convention) and print
  "Command '<name>' timed out after <timeout>s".
- **FR-007**: The CLI MUST expose
  `kiss integration list [--catalog]`,
  `kiss integration install <key> …`,
  `kiss integration uninstall [<key>] [--force]`,
  `kiss integration switch <target> …`,
  `kiss integration upgrade [<key>] …`
  (`cli/integration.py:91,181,261,345,472`).
  Per-command FRs are detailed in `kiss-install/spec.md`,
  `kiss-uninstall/spec.md`, and `kiss-upgrade/spec.md`.
- **FR-008**: *(Extracted)* See `docs/specs/kiss-check/spec.md`
  FR-001 through FR-009 for the full `kiss check` contract.
- **FR-009**: *(Extracted)* See `docs/specs/kiss-check/spec.md`
  FR-003 (aggregate exit code) and FR-004 (run to completion).
- **FR-009a**: *(Extracted)* See `docs/specs/kiss-check/spec.md`
  FR-005 (Rich table output) and FR-009 (fix suggestions).
- **FR-010**: `IntegrationCatalog` MUST list every
  discoverable integration entry
  (`integrations/catalog.py:1-511`); community catalog
  refresh may require network — **RDEBT-023**.
- **FR-011**: Asset integrity MUST be verifiable via
  `_integrity.verify_asset_integrity(core_pack_root)`
  (`_integrity.py:24-79`); on tampering it MUST raise
  `AssetCorruptionError` (`_integrity.py:11-21`).
  Wiring this into the runtime path is **RDEBT-003** /
  TDEBT-002.
- **FR-012**: The system MUST NOT support plugin
  discovery — every integration is registered inline
  (ADR-009).
- **FR-013**: `bundle_skill_assets` MUST copy every skill's
  `scripts/bash/`, `scripts/powershell/`, and `templates/`
  alongside the installed `SKILL.md` (or equivalent)
  (`skill_assets.py:79-127`).
- **FR-014**: Custom-agent / subagent prompts from
  `subagents/` MUST be installed into each integration's
  subagent folder per the per-AI mapping in
  `docs/specs/subagent-system/spec.md` Key Entities. The
  exact target rule per integration is captured in
  **RDEBT-027** (supersedes RDEBT-020).
- **FR-015**: Every integration's `setup` MUST be
  idempotent under repeated `kiss integration install` —
  re-running with the same key + version produces an
  equivalent manifest (verified by FR-008's
  `kiss check` flow).
- **FR-016**: The integration registry MUST contain
  **exactly the seven supported AIs** listed below, per
  ADR-018 and `docs/AI-urls.md`.

  | # | Key | Display name | Agent file | Skills format | Subagent / equivalent format | WebFetch source |
  |---|-----|--------------|------------|---------------|------------------------------|-----------------|
  | 1 | `claude` | Claude Code | `<root>/CLAUDE.md` | agentskills.io `SKILL.md` folder; `.claude/skills/<name>/SKILL.md` | Markdown subagents under `.claude/agents/`; YAML frontmatter (`name`, `description`, optional `tools`, `model`) | `code.claude.com/docs/en/sub-agents`, `platform.claude.com/docs/en/agents-and-tools/agent-skills/overview`, `platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices` |
  | 2 | `copilot` | GitHub Copilot | `<root>/AGENTS.md` | agentskills.io `SKILL.md`; `.github/skills/`, `.claude/skills/`, `.agents/skills/` | VS Code custom agents `*.agent.md` under `.github/agents/` or `.claude/agents/`; YAML frontmatter (`name`, `description`, optional `tools`, `model`, `agents`, `handoffs`, `user-invocable`, `disable-model-invocation`, `hooks`) | `docs.github.com/en/copilot/concepts/agents/about-agent-skills`, `code.visualstudio.com/docs/copilot/customization/subagents` |
  | 3 | `cursor_agent` | Cursor Agent | `<root>/AGENTS.md` | agentskills.io `SKILL.md`; `.agents/skills/`, `.cursor/skills/` (plus user equivalents) | Markdown subagents under `.cursor/agents/`, `.claude/agents/`, `.codex/agents/`; YAML frontmatter (`name`, `description`, optional `model`, `readonly`, `is_background`) | `cursor.com/docs/skills`, `cursor.com/docs/subagents` |
  | 4 | `opencode` | OpenCode | `<root>/AGENTS.md` | agentskills.io `SKILL.md`; `.opencode/skills/<name>/SKILL.md`, `.claude/skills/<name>/SKILL.md`, `.agents/skills/<name>/SKILL.md` | Markdown agents with `mode: subagent` under `.opencode/agents/`; frontmatter `description` required, `mode`, optional model / temp / permission | `opencode.ai/docs/agents/`, `opencode.ai/docs/skills/` |
  | 5 | `windsurf` | Windsurf (Cascade) | `<root>/AGENTS.md` | `SKILL.md` folder under `.windsurf/skills/<name>/`, `~/.codeium/windsurf/skills/<name>/` | **Workflows** ≈ subagents; `.md` under `.windsurf/workflows/`, max 12 000 chars, manual `/<name>` invocation | `docs.windsurf.com/windsurf/cascade/skills`, `docs.windsurf.com/windsurf/cascade/workflows`. Mapping is approximate — RDEBT-025 |
  | 6 | `gemini` | Gemini CLI | `<root>/GEMINI.md` | agentskills.io `SKILL.md` under `.gemini/skills/`, `.agents/skills/` (plus user equivalents); also `.skill` zip distribution | Markdown subagents under `.gemini/agents/`; YAML frontmatter (`name`, `description`, optional `kind`, `tools`, `mcpServers`, `model`, `temperature`, `max_turns`, `timeout_mins`) | `geminicli.com/docs/cli/skills/`, `geminicli.com/docs/core/subagents/` |
  | 7 | `codex` | Codex (OpenAI) | `<root>/AGENTS.md` | `SKILL.md` directory; optional `agents/openai.yaml`; metadata cap ≈ 2 % of context (≈ 8 000 chars) | TOML subagents under `.codex/agents/`; required keys `name`, `description`, `developer_instructions`; optional `nickname_candidates`, `model`, `model_reasoning_effort`, `sandbox_mode`, `mcp_servers`, `skills.config` | `developers.openai.com/codex/skills`, `developers.openai.com/codex/subagents` |

- **FR-018**: Each integration's `setup` MUST write files
  only to its own primary directory tree (e.g. Claude →
  `.claude/`, Copilot → `.github/`, Cursor → `.cursor/`,
  OpenCode → `.opencode/`, Windsurf → `.windsurf/`, Gemini →
  `.gemini/`, Codex → `.codex/`). Cross-agent fallback
  folders (`.agents/skills/`, `.claude/skills/` from non-
  Claude integrations) MUST NOT be populated by kiss; they
  exist as user-managed directories that AI tools may read
  from independently.
- **FR-017**: The following integration keys were
  **removed (2026-04-26)** per ADR-018: `kiro_cli`, `auggie`,
  `tabnine`, `kilocode`, `agy`, `generic`.

### Non-Functional Requirements

- **NFR-001 (Offline)**: `setup`, `teardown`, and the
  dispatch wrapper MUST not perform network I/O for kiss-
  internal work (ADR-003); the AI CLI subprocesses spawned
  by `dispatch_command` may.
- **NFR-002 (Cross-platform)**: Linux, Windows; macOS
  asserted (RDEBT-005).
- **NFR-003 (Shell parity)**: `bundle_skill_assets` MUST
  install both Bash and PowerShell flavours (ADR-006 /
  ADR-015).
- **NFR-004 (Coverage)**: ≥ 80 % on changed files
  (RDEBT-006).
- **NFR-005 (Complexity / size)**: ≤ 40 LOC / function,
  complexity ≤ 10. `integrations/base.py` is 1,374 LOC
  (TDEBT-022) — per-function discipline still required.
- **NFR-006 (Lint)**: Zero Ruff warnings on changed files
  (ADR-016).
- **NFR-007 (Determinism)**: Repeated installs against the
  same wheel and project produce manifests with identical
  per-file hashes.
- **NFR-008 (Asset integrity)**: The wheel MUST embed
  `core_pack/sha256sums.txt`; verification MUST be
  runnable (FR-011); production wiring is RDEBT-003.
- **NFR-009 (Manifest contract)**: ADR-004 — every file
  kiss writes for an integration is hashed.

### Key Entities

- **`IntegrationBase`** —
  `integrations/base.py:56`. Abstract base with `setup`,
  `teardown`, `dispatch_command`, `build_command_invocation`.
- **`MarkdownIntegration`** — `integrations/base.py:865+`.
- **`TomlIntegration`** — `integrations/base.py:963+`.
- **`SkillsIntegration`** — `integrations/base.py:…`.
- **`IntegrationManifest`** —
  `integrations/manifest.py:50-265`.
- **`IntegrationCatalog`** —
  `integrations/catalog.py:1-511`.
- **`INTEGRATION_REGISTRY`** —
  `integrations/__init__.py:16`.
- **`_integrity.verify_asset_integrity`** —
  `_integrity.py:24-79`.
- **`_integrity.AssetCorruptionError`** —
  `_integrity.py:11-21`.
- **Supported AI list (target state per ADR-018)** —
  exactly the seven AIs in FR-016. Authoritative source
  of truth: `docs/AI-urls.md` and
  `docs/research/ai-providers-2026-04-26.md`.
- **Subagent install** — covered by
  `docs/specs/subagent-system/spec.md`.

## Success Criteria

### Measurable Outcomes

- **SC-001**: All seven supported integrations install end-
  to-end via `tests/test_init_multi.py` on every CI cell
  (per ADR-018).
- **SC-002**: Every install produces a manifest where every
  recorded SHA-256 matches the on-disk file (verified post-
  install).
- **SC-003**: `kiss check` aggregate exits with code `0` on
  a freshly-initialised project for every supported
  integration. (See `docs/specs/kiss-check/spec.md` SC-001
  for the full acceptance criterion.)
- **SC-004**: Adding a new integration (within the seven
  supported AIs) requires changes to exactly two files: a
  new `integrations/<name>/__init__.py` and a one-line
  registration in `_register_builtins()` (per ADR-009).
- **SC-005**: Asset integrity is verifiable from the wheel
  via `verify_asset_integrity` (when invoked). Production
  call site is tracked as RDEBT-003.

## Assumptions

- The seven supported AIs are the authoritative list per
  `docs/AI-urls.md`; extending the list requires a new
  ADR (cross-link to ADR-018, which is `Accepted`).
- The standards' Principle IV (pure / deterministic) holds:
  every `setup` produces identical hashes given identical
  inputs.
- The user can install multiple integrations both at `kiss init`
  (multi-select) and post-init via repeated
  `kiss integration install <key>` calls. Each integration
  owns a disjoint directory tree and a separate manifest.
- AI providers' command file conventions stay stable per
  major-version. When they break, kiss releases a new minor
  with the updated mapping.
- Custom-agent / subagent prompts apply per the per-AI
  mapping in `docs/specs/subagent-system/spec.md`. RDEBT-027
  captures the unverified mapping question.

## Out of Scope

- Authoring AI provider CLIs or services (kiss is the bridge,
  not the provider).
- Plugin-style discovery of community integrations
  (ADR-009 — by design).
- ~~Multi-integration co-existence post-init~~ — now
  supported; see `kiss-install/spec.md` FR-004.
- Sandboxing or signing the AI CLI subprocesses spawned by
  `dispatch_command`.
- Cross-version manifest-schema migration.
- Re-introducing `kiro_cli`, `auggie`, `tabnine`, `kilocode`,
  `agy`, or `generic` without a superseding ADR.
- The agent-skills bundles themselves (covered by
  `agent-skills-system/spec.md`) and the role-agent /
  subagent installation flow (covered by
  `subagent-system/spec.md`).

## Traceability

- **ADRs**: ADR-001 (CLI framework), ADR-003 (offline),
  ADR-004 (manifests), ADR-005 (three formats), ADR-006
  (parity), ADR-007 (asset integrity), ADR-009 (static
  registry), ADR-011 (context.yml), ADR-015 (parity
  invariant), ADR-018 (narrow integration scope to seven
  AIs).
- **Source modules**:
  `src/kiss_cli/integrations/__init__.py:14-84`;
  `src/kiss_cli/integrations/base.py:56-1374`;
  `src/kiss_cli/integrations/manifest.py:50-265`;
  `src/kiss_cli/integrations/catalog.py:1-511`;
  `src/kiss_cli/cli/integration.py:91-582`;
  `src/kiss_cli/cli/check.py:1-639`;
  `src/kiss_cli/_integrity.py:24-99`;
  `src/kiss_cli/installer.py:429-494` (subagents).
- **Tests**: `tests/test_init_multi.py`,
  `tests/test_offline.py`,
  `tests/test_asset_integrity.py`.
- **Bundled assets**: 7 integration packages on disk
  (claude, copilot, gemini, cursor_agent, windsurf, codex,
  opencode) per FR-016. The former agy, auggie, kilocode,
  kiro_cli, tabnine, and generic packages were removed
  2026-04-26.
- **Research / source of truth**:
  `docs/AI-urls.md`,
  `docs/research/ai-providers-2026-04-26.md`.
- **Related specs**: `kiss-install/spec.md`,
  `kiss-uninstall/spec.md`, `kiss-upgrade/spec.md`,
  `agent-skills-system/spec.md`,
  `subagent-system/spec.md`,
  `build-and-distribution/spec.md`,
  `workflow-engine/spec.md` (depends on `dispatch_command`).
- **Related debts**: RDEBT-003 (asset integrity wiring),
  RDEBT-004 (13 vs 14 count — superseded by RDEBT-024),
  RDEBT-005, RDEBT-006, RDEBT-007,
  RDEBT-009 (resolved — multi-integration supported),
  RDEBT-017 ("max" exit code),
  RDEBT-022 (catalog trust),
  RDEBT-023 (catalog network),
  RDEBT-024 (resolved — source narrowed to 7 AIs),
  RDEBT-025 (Windsurf workflows ≈ subagents — approximate),
  RDEBT-026 (per-AI agent-file & skill-folder layout
  unverified against installer),
  RDEBT-027 (subagents target — supersedes RDEBT-020);
  cross-link TDEBT-002, TDEBT-008, TDEBT-010, TDEBT-022,
  TDEBT-024, TDEBT-028 (resolved — source narrowed to 7
  AIs).
