# Feature Specification: kiss-upgrade

**Feature Slug**: `kiss-upgrade`
**Created**: 2026-04-26
**Status**: Draft (reverse-engineered)
**Mode**: auto
**Input**: `docs/upgrade.md`, `cli/init.py:76-599` (used in
`--here --force` mode), `cli/integration.py:472-…`,
`integrations/manifest.py:50-265`.

## Problem Statement

A developer who has previously run `kiss init` against a project
needs a safe way to refresh the kiss-managed files (skills,
templates, scripts, role-agents, bundled extensions and workflows,
agent context blocks) when a newer kiss release ships — without
touching the user's source code, specifications under `docs/`, or
local customisations they want to keep. The upgrade path must:

- preserve `docs/standards.md`, `docs/specs/`, `docs/plans/`,
  `docs/tasks/`, source code, and git history;
- detect locally-modified template files via SHA-256 manifest
  hashes and refuse to clobber them unless `--force` is supplied;
- run entirely offline (the new kiss release is already in the
  installed wheel after `uv tool install --force`).

Today the user-facing upgrade workflow is documented as two steps
(`docs/upgrade.md`):

1. CLI tool upgrade — `uv tool install kiss --force …` (out of
   `kiss`'s own surface).
2. Project-files upgrade — `kiss init --here --force --ai <agent>`
   for the asset refresh, plus optionally
   `kiss integration upgrade <key>` for diff-aware integration
   refresh.

There is no top-level `kiss upgrade` command — the docs reference
one (`docs/upgrade.md:49-57`) but the implementation is the two
flows above. **RDEBT-001** captures the gap.

Source evidence: `docs/upgrade.md:1-167`,
`src/kiss_cli/cli/init.py:148-183` (the `--here --force` path),
`src/kiss_cli/cli/integration.py:472-582` (`integration upgrade`).

## User Scenarios & Testing

### User Story 1 — Refresh kiss-managed assets in an existing project (Priority: P1)

As a developer who installed kiss six months ago, I want to run
`kiss init --here --force --integration claude` after upgrading
my CLI, so that my project picks up new slash commands, refreshed
templates, and the latest role-agent prompts — and my `docs/`
directory, source code, and git history stay completely
untouched.

**Why this priority**: This is the documented upgrade flow; users
will run it on every kiss release.

**Independent test**: Modify a file under `docs/specs/` and a
file under `src/`; run the upgrade; confirm both are unchanged
while skill files in `.claude/skills/` are refreshed.

**Acceptance Scenarios**:

1. **Given** an existing kiss project with a populated `docs/`,
   **When** the user runs
   `kiss init --here --force --integration claude`, **Then**
   files under `docs/`, source code, and `.git/` are unchanged
   (`docs/upgrade.md:67-77`).
2. **Given** the same project, **When** the upgrade runs,
   **Then** every installed skill folder
   (e.g. `.claude/skills/kiss-specify/`) — including `SKILL.md`
   plus the bundled `scripts/` and `templates/` — is rewritten
   from the new wheel (`docs/upgrade.md:62-65,104-108`).
3. **Given** the project has a managed agent context file
   (e.g. `CLAUDE.md` with `<!-- KISS START -->` /
   `<!-- KISS END -->` markers), **When** the upgrade runs,
   **Then** only the managed section is refreshed; content
   outside the markers is preserved (`docs/upgrade.md:62-65`).

### User Story 2 — Diff-aware integration upgrade (Priority: P1)

As a developer who edited a few skill files locally, I want to
run `kiss integration upgrade claude` so that kiss compares the
manifest hashes, lists the files I have modified, and refuses to
overwrite them unless I add `--force`.

**Why this priority**: Protects user customisations. Without
this, every upgrade silently destroys local edits.

**Independent test**: Hand-edit a file under
`.claude/skills/kiss-specify/`; run
`kiss integration upgrade claude`; confirm the command lists the
file and exits with code `1`.

**Acceptance Scenarios**:

1. **Given** a project with one or more locally-modified files
   recorded in the integration manifest, **When** the user runs
   `kiss integration upgrade claude`, **Then** the command
   prints the list of modified files and exits with code `1`
   without writing anything (`cli/integration.py:528-535`).
2. **Given** the same setup, **When** the user re-runs with
   `--force`, **Then** the modified files are overwritten with
   the new versions and the command succeeds
   (`cli/integration.py:530-535,540`).
3. **Given** the upgrade succeeds, **When** the new manifest is
   compared with the old, **Then** files present in the old
   manifest but absent from the new one ("stale" files) are
   removed (`cli/integration.py:570-579`).

### User Story 3 — Upgrade succeeds when the user is offline (Priority: P1)

As a developer on a flight, I want to upgrade my project's kiss
assets without touching the network.

**Acceptance Scenarios**:

1. **Given** no network connection, **When** the upgrade runs
   (after `uv tool install --force` was performed earlier on the
   ground), **Then** the upgrade completes successfully because
   every asset is in the bundled `core_pack/`
   (`_bundled_catalogs.py:28-45`,
   `tests/test_offline.py`).

### User Story 4 — Upgrade aborts cleanly on integration setup failure (Priority: P2)

As a developer running an upgrade that hits a programming error
mid-run, I want kiss to leave my project in a recoverable state
(no half-written manifest), rather than wedge the install.

**Acceptance Scenarios**:

1. **Given** `integration.setup` raises during upgrade, **When**
   the failure occurs, **Then** kiss prints the error, warns
   "The previous integration files may still be in place", and
   exits with code `1` *without* tearing down the previous
   install (`cli/integration.py:563-568`).

### User Story 5 — Refresh shared infrastructure (`.kiss/`) while preserving customizations (Priority: P2)

As a developer upgrading, I want the `.kiss/` shared
infrastructure (e.g. helper scripts) to be refreshed alongside
the per-AI files — but I want my customizations in
`.kiss/context.yml` (e.g. `language.output`, custom `paths.docs`)
preserved, not overwritten from the bundled template.

**Acceptance Scenarios**:

1. **Given** an upgrade is in progress, **When**
   `_install_shared_infra(project_root, force=True)` runs,
   **Then** existing files under `.kiss/` are overwritten with
   the new bundled versions — EXCEPT `.kiss/context.yml`, which
   MUST be merged: new keys from the bundled template are added,
   but existing user-customized values are preserved
   (`cli/integration.py:540`, `installer.py:393-410`).
2. **Given** the user has set `language.output: Vietnamese` and
   `paths.docs: documentation`, **When** the upgrade runs,
   **Then** those values remain after upgrade; only new schema
   keys (e.g. a new `preferences.*` field added in the new
   kiss version) are populated from the template defaults.

### Edge Cases

- **No manifest exists for the integration**: `kiss integration
  upgrade <key>` exits with code `0` and prints "Nothing to
  upgrade" — the user must run `install` first
  (`cli/integration.py:516-520`).
- **Manifest is unreadable** (corrupted JSON):
  `cli/integration.py:522-526` exits with code `1` and prints
  "Integration manifest for '<key>' is unreadable: …".
- **User asks to upgrade a different integration than the one
  installed**: `cli/integration.py:504-509` exits with code `1`
  and suggests `kiss integration switch <key>` instead.
- **`--no-git` upgrade**: kiss does not create or change the git
  state during upgrade (`docs/upgrade.md:198-210`).
- **No integration installed at all**: `kiss integration upgrade`
  (no key) exits with code `0` and prints "No integration is
  currently installed" (`cli/integration.py:498-502`).
- **Skipped files in `_install_shared_infra` without `--force`**:
  the CLI prints a warning listing the skipped files
  (`docs/upgrade.md:106-108`).
- **Network unavailable**: upgrade MUST still succeed because
  assets ship inside the wheel (NFR-001).
- **Permission denied on a target file**: surfaces as the
  underlying `OSError`. Behaviour is undocumented; expected to
  abort with code `1`. **(AI suggestion — confirm)** —
  see **RDEBT-016**.
- **Manifest mismatch resolution policy**: today only
  `--force` exists as the override; no per-file interactive
  resolution. **RDEBT-010** captures this.

## Requirements

### Functional Requirements

- **FR-001**: The CLI MUST expose `kiss integration upgrade
  [<key>] [--all] [--force] [--script sh|ps]
  [--integration-options]` (`cli/integration.py:472-…`).
- **FR-002**: When `<key>` is omitted AND exactly one integration
  is installed, the CLI MUST upgrade that integration. When
  `<key>` is omitted AND multiple integrations are installed,
  the CLI MUST exit with code `1` and list the installed
  integrations, asking the user to specify which one to upgrade
  (or use `--all`). When `--all` is supplied, the CLI MUST
  upgrade every installed integration in sequence, stopping at
  the first failure. When no integrations are installed, the
  CLI MUST exit with code `0` and print "No integration is
  currently installed" (`cli/integration.py:498-502`).
- **FR-003**: When `<key>` does not match the installed
  integration, the CLI MUST exit with code `1` and suggest
  `kiss integration switch <key>` (`cli/integration.py:504-509`).
- **FR-004**: The CLI MUST load the existing manifest from
  `.kiss/integrations/<key>.manifest.json`; missing manifest
  MUST exit with code `0` and print "Nothing to upgrade"
  (`cli/integration.py:516-520`).
- **FR-005**: The CLI MUST detect locally-modified files via
  `IntegrationManifest.check_modified()` and abort with code `1`
  if any are present, unless `--force` is supplied
  (`cli/integration.py:528-535`).
- **FR-006**: The CLI MUST refresh `.kiss/` shared infrastructure
  by calling `_install_shared_infra(project_root, force=force)`
  (`cli/integration.py:540`).
- **FR-007**: The CLI MUST chmod `*.sh` files on POSIX after
  upgrade (`cli/integration.py:541-542`).
- **FR-008**: The CLI MUST run the integration's `setup` against
  a *new* `IntegrationManifest`, then save the new manifest
  (`cli/integration.py:546-561`).
- **FR-009**: The CLI MUST identify "stale" files (present in
  the old manifest but absent from the new manifest) and remove
  them via a force-uninstall pass over the stale subset
  (`cli/integration.py:570-579`).
- **FR-010**: On `setup` failure during upgrade, the CLI MUST
  NOT call `teardown`; it MUST report "The previous integration
  files may still be in place" and exit with code `1`
  (`cli/integration.py:563-568`).
- **FR-011**: The CLI MUST also support the documented
  whole-project refresh path:
  `kiss init --here --force [--integration <key>]`
  (`docs/upgrade.md:78-93`,
  `cli/init.py:148-183`).
- **FR-012**: In the `--here --force` upgrade path, the CLI MUST
  NOT modify any file under `docs/`, source code, or `.git/`
  (`docs/upgrade.md:67-77`); only kiss-managed assets are
  rewritten.
- **FR-013**: For agent context files
  (e.g. `CLAUDE.md`, `GEMINI.md`,
  `.cursor/rules/kiss-rules.mdc`), upgrade MUST refresh only the
  managed block between `<!-- KISS START -->` /
  `<!-- KISS END -->` markers; content outside the markers MUST
  be preserved (`docs/upgrade.md:62-65`).
- **FR-014**: Upgrade MUST NOT perform any network I/O — it MUST
  resolve every asset from the bundled `core_pack/`
  (`_bundled_catalogs.py:28-45`,
  `tests/test_offline.py`).
- **FR-016**: Upgrade MUST NOT overwrite user-customized values
  in `.kiss/context.yml`. The merge strategy is: load the
  existing `context.yml`, load the bundled template, add any
  new keys from the template that do not exist in the user's
  file, and preserve all existing user values. The
  `schema_version` field MUST be updated to the new version
  if it has changed.
- **FR-015**: Upgrade MUST update `.kiss/init-options.json`
  `kiss_version` to the running CLI's version
  (`cli/integration.py:561-562`,
  `config.py:10-19`).

### Non-Functional Requirements

- **NFR-001 (Offline)**: Upgrade MUST not perform network I/O
  per ADR-003.
- **NFR-002 (Cross-platform)**: Linux, Windows; macOS asserted
  but not in CI (RDEBT-005 / TDEBT-014).
- **NFR-003 (Shell parity)**: Upgrade MUST refresh both
  `scripts/bash/` and `scripts/powershell/` per skill
  (ADR-006 / ADR-015).
- **NFR-004 (Coverage)**: Functions in
  `cli/integration.py:472-582` (and the shared upgrade helpers
  in `installer.py`, `integrations/manifest.py`) MUST hold
  ≥ 80 % line coverage on changed files (RDEBT-006 /
  TDEBT-015).
- **NFR-005 (Complexity)**: All upgrade functions MUST stay
  ≤ 40 executable LOC and complexity ≤ 10
  (Principle III / RDEBT-007).
- **NFR-006 (Lint)**: Zero Ruff warnings on changed files
  (ADR-016).
- **NFR-007 (Performance — qualitative)**: Upgrade MUST complete
  "within seconds" on a developer laptop (RDEBT-002 /
  TDEBT-017).
- **NFR-008 (Determinism)**: Two upgrades against the same
  installed wheel MUST produce identical post-state hashes,
  per Principle IV.
- **NFR-009 (Idempotence)**: Re-running an upgrade with no
  intervening change MUST be a no-op in observable behaviour
  (modulo timestamps).

### Key Entities

- **Old `IntegrationManifest`** — read from
  `.kiss/integrations/<key>.manifest.json`. Used to compute
  modified-files set and stale-files set
  (`integrations/manifest.py:50-265`).
- **New `IntegrationManifest`** — created during the upgrade
  run, populated as `setup` writes files, then saved.
- **Stale-files manifest** — a synthetic
  `IntegrationManifest("stale-cleanup")` constructed from
  `old_files - new_files` and used to drive the targeted
  cleanup (`cli/integration.py:574-579`).
- **`<!-- KISS START -->` / `<!-- KISS END -->` markers** —
  delimiters in agent context files that bound the kiss-managed
  region (`docs/upgrade.md:62-65`).

## Success Criteria

### Measurable Outcomes

- **SC-001**: After upgrade, every file listed in the new
  integration manifest hashes to the value the manifest records
  (no drift).
- **SC-002**: A user with locally-modified files is never
  surprised by a silent overwrite — modified files are listed
  before any write happens (`cli/integration.py:530-534`).
- **SC-003**: No file under `docs/`, `src/`, or `.git/` is
  modified by `kiss init --here --force`
  (`docs/upgrade.md:67-77`); verifiable by hashing those trees
  before and after.
- **SC-004**: Upgrade performs zero network I/O — defended by
  `tests/test_offline.py` (and ADR-017 once that test is
  extended to cover all subcommands).

## Assumptions

- The CLI tool itself has already been upgraded by the user
  (e.g. via `uv tool install kiss --force …`); this spec covers
  the project-side upgrade only.
- The user's project was originally scaffolded by a recent kiss
  version that wrote a per-integration manifest. Pre-manifest
  installs are an unknown migration path.
- The user has not deleted `.kiss/integrations/<key>.manifest.json`
  manually — if they have, FR-004 sends them back to
  `kiss integration install <key>`.

## Out of Scope

- Upgrading the CLI tool itself (`uv tool install kiss --force`
  is the user's responsibility — `docs/upgrade.md:17-44`).
- Migrating user-authored content under `docs/specs/`,
  `docs/plans/`, `docs/tasks/`. Those are explicitly preserved.
- Per-file interactive merge resolution
  (RDEBT-010 — today only `--force` exists).
- Cross-version schema migration of `.kiss/init-options.json`
  (today no migration logic exists; it is rewritten from the
  bundled template). Note: `.kiss/context.yml` IS merge-
  preserved on upgrade (see User Story 5) — only new schema
  keys are added from the template; existing values are kept.

## Traceability

- **ADRs**: ADR-003 (offline), ADR-004 (manifests), ADR-006
  (parity), ADR-011 (context.yml), ADR-015 (parity invariant),
  ADR-017 (boundary tests).
- **Source modules**:
  `src/kiss_cli/cli/integration.py:472-582` (`integration
  upgrade`);
  `src/kiss_cli/cli/init.py:148-183` (`--here --force` path);
  `src/kiss_cli/integrations/manifest.py:50-265`
  (`check_modified`, `uninstall`);
  `src/kiss_cli/installer.py:393-410` (`_install_shared_infra`).
- **User docs**: `docs/upgrade.md` — the user-facing flow.
- **Tests**: `tests/test_init_multi.py`,
  `tests/test_offline.py`, `tests/test_extensions.py`,
  `tests/test_presets.py`.
- **Related specs**: `kiss-init/spec.md`,
  `integration-system/spec.md`,
  `agent-skills-system/spec.md`.
- **Related debts**: RDEBT-001 (no top-level `kiss upgrade`),
  RDEBT-002 (perf NFR), RDEBT-006 (coverage), RDEBT-010
  (manifest mismatch resolution), RDEBT-016 (permission-denied),
  RDEBT-023 (offline scope).
