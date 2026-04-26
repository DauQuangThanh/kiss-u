# Feature Specification: build-and-distribution

**Feature Slug**: `build-and-distribution`
**Created**: 2026-04-26
**Status**: Draft (reverse-engineered)
**Mode**: auto
**Input**: `pyproject.toml:1-101`,
`scripts/hatch_build_hooks.py:1-144`,
`scripts/generate-checksums.py:1-71`,
`.github/workflows/release.yml:1-141`,
`.github/workflows/test.yml:1-55`,
`.github/workflows/lint.yml`,
`.github/workflows/codeql.yml`,
`.github/workflows/validate-skills.yml`,
`_integrity.py:24-99`,
`installer.py:301-391`,
`_bundled_catalogs.py:1-64`,
`cli/version.py:12-39`.

## Problem Statement

kiss must be reliably built, packaged, distributed, and
installed in a way that:

- bundles every preset, extension, workflow, agent skill, and
  integrations catalog into the wheel so that runtime is
  offline-only (CLAUDE.md "Offline operation");
- attaches a SHA-256 checksum file to every wheel build, so
  asset corruption or wheel tampering is detectable;
- runs cross-platform tests (Linux + Windows) on three
  Python versions (3.11, 3.12, 3.13) before any release tag is
  cut;
- triggers releases via tag push only (no auto-publish to
  PyPI), per ADR-008;
- exposes a `kiss version` / `kiss --version` surface so users
  can confirm what they have installed.

Source evidence:
- `pyproject.toml:1-101` — package metadata, dependencies,
  build backend (hatchling), force-include for
  `build/core_pack/` → `kiss_cli/core_pack/`.
- `scripts/hatch_build_hooks.py:1-144` — the
  `CustomBuildHook` that stages assets at build time.
- `scripts/generate-checksums.py:1-71` — the
  `core_pack/sha256sums.txt` generator invoked from the
  hook.
- `.github/workflows/test.yml:30-55` — the test matrix
  `{ubuntu, windows} × {3.11, 3.12, 3.13}`.
- `.github/workflows/release.yml:1-141` — tag-triggered
  build of wheel + sdist + `SHA256SUMS`, attached to GitHub
  Release.
- `_integrity.py:24-99` — runtime asset-integrity
  verification (defined; current production wiring is
  RDEBT-003).
- `installer.py:301-391` — runtime resolver
  (`_locate_core_pack`, `_locate_bundled_*`).
- `_bundled_catalogs.py:1-64` — offline catalog loader.
- `cli/version.py:12-39` — `kiss version` command.

## User Scenarios & Testing

### User Story 1 — Build a wheel with bundled assets (Priority: P1)

As a kiss maintainer cutting a release, I want
`uv build --wheel --sdist` to:

1. wipe `build/core_pack/`;
2. mirror the five asset trees (`agent-skills/`,
   `subagents/`, `presets/`, `extensions/`, `workflows/`) plus
   `integrations/catalog.json` into it;
3. exclude developer scaffolding (paths whose part starts
   with `_`) and noise (`.DS_Store`, `__pycache__`,
   `.pytest_cache`, `*.pyc`, `*.pyo`);
4. shell out to `scripts/generate-checksums.py` to produce
   `build/core_pack/sha256sums.txt`;
5. let hatchling include `build/core_pack/` as
   `kiss_cli/core_pack/` inside the wheel.

**Acceptance Scenarios**:

1. **Given** a clean checkout, **When** `uv build --wheel
   --sdist` is run, **Then** the wheel contains
   `kiss_cli/core_pack/agent-skills/`,
   `kiss_cli/core_pack/subagents/`,
   `kiss_cli/core_pack/presets/`,
   `kiss_cli/core_pack/extensions/`,
   `kiss_cli/core_pack/workflows/`,
   `kiss_cli/core_pack/integrations/catalog.json`, and
   `kiss_cli/core_pack/sha256sums.txt`
   (`scripts/hatch_build_hooks.py:32-48,107-138`,
   `pyproject.toml:41-42`).
2. **Given** the build hook fails to generate checksums,
   **When** the build runs, **Then** it raises
   `RuntimeError("Asset checksum generation failed")`
   (`scripts/hatch_build_hooks.py:144`).

### User Story 2 — Sdist reproduces wheel build (Priority: P2)

As a kiss maintainer, I want the sdist to include the repo-
root asset directories so that building a wheel from the sdist
reproduces the same `kiss_cli/core_pack/` layout.

**Acceptance Scenarios**:

1. **Given** a built sdist, **When** `uv build --wheel` is
   run from the unpacked sdist, **Then** the resulting wheel
   has the same `kiss_cli/core_pack/` contents as a wheel built
   from the source tree (`pyproject.toml:44-70`).

### User Story 3 — Offline runtime after install (Priority: P1)

As an end user, I want every `kiss` command — `init`,
`upgrade`, `integration *`, `preset *`, `extension *`,
`workflow *`, `check *` — to work without any network access
once `uv tool install kiss` is done.

**Acceptance Scenarios**:

1. **Given** the wheel is installed, **When** the user runs
   `kiss init` on an air-gapped machine, **Then** the command
   completes successfully (`tests/test_offline.py`).
2. **Given** the same setup, **When** kiss reads any catalog,
   **Then** the read is satisfied by
   `_locate_bundled_catalog_file()`
   (`_bundled_catalogs.py:28-45`).

### User Story 4 — Cross-platform CI matrix (Priority: P1)

As a kiss maintainer, I want CI to run pytest on every push
across the supported matrix `{ubuntu-latest, windows-latest} ×
{Python 3.11, 3.12, 3.13}` so I never ship a release that
fails on a supported platform.

**Acceptance Scenarios**:

1. **Given** a pull request is opened, **When** the
   `.github/workflows/test.yml` workflow runs, **Then** all
   six matrix cells execute pytest and Ruff
   (`.github/workflows/test.yml:18-55`).
2. **Given** the Windows cell, **When** bash tests run,
   **Then** `tests/conftest.py::_has_working_bash` gates them
   on the presence of Git-for-Windows MSYS bash and skips
   gracefully if absent (`.github/workflows/test.yml:50-53`).

> **Note**: macOS is not in the matrix; CLAUDE.md asserts
> macOS support. See **RDEBT-005** / TDEBT-014.

### User Story 5 — Tag-triggered release (Priority: P1)

As a kiss maintainer, I want pushing a `v*` tag to:

1. build wheel + sdist via `uv build`;
2. compute and attach a `SHA256SUMS` file;
3. publish a GitHub Release with the artefacts.

…and I want **no** automatic PyPI publish to be wired (per
ADR-008) so that I have a manual checkpoint before public
distribution.

**Acceptance Scenarios**:

1. **Given** a maintainer pushes a tag matching `v*`, **When**
   the `.github/workflows/release.yml` workflow runs, **Then**
   it builds the artefacts, computes `SHA256SUMS`, and creates
   a GitHub Release with all three attached
   (`.github/workflows/release.yml:1-141`).
2. **Given** the same workflow, **When** the build completes,
   **Then** the workflow does NOT push to PyPI
   (ADR-008 / TDEBT-018).

### User Story 6 — `kiss version` surface (Priority: P2)

As a user troubleshooting, I want to run `kiss version` to see
the installed CLI version, Python version, platform, arch, and
OS version.

**Acceptance Scenarios**:

1. **Given** kiss is installed, **When** the user runs
   `kiss version`, **Then** the command prints a Rich panel
   with version + system info (`cli/version.py:12-39`).
2. **Given** the user runs `kiss --version` (or `kiss -V`),
   **When** the command runs, **Then** the version is printed
   and the process exits via the eager option callback
   (`cli/__init__.py:24`).
3. **Given** the package metadata is missing AND
   `pyproject.toml` cannot be read, **When** version lookup
   runs, **Then** `get_kiss_version()` returns `"unknown"`
   (`cli/version.py`, `version.py:7-23`).

### User Story 7 — Asset integrity verifiable from the wheel (Priority: P2)

As a security-conscious user, I want `_integrity.
verify_asset_integrity` to validate
`core_pack/sha256sums.txt` against the actual files in the
installed wheel, and raise `AssetCorruptionError` on
tampering.

**Acceptance Scenarios**:

1. **Given** an intact wheel install, **When**
   `verify_asset_integrity(core_pack_root)` runs, **Then** it
   returns success (`_integrity.py:24-79`).
2. **Given** a tampered file, **When** verification runs,
   **Then** `AssetCorruptionError` is raised
   (`_integrity.py:11-21`).

> **Note**: As of 2026-04-26, no production caller invokes
> this function during normal `kiss init` /
> `kiss integration upgrade`. ADR-007 commits to wiring it;
> the work is **RDEBT-003** / TDEBT-002.

### Edge Cases

- **`build/core_pack/` is partially populated by a previous
  build**: the build hook wipes and re-creates it
  (`hatch_build_hooks.py:113-115`).
- **A skill folder name starts with `_`**: excluded from the
  wheel (`hatch_build_hooks.py:51-71`); cannot be installed at
  runtime.
- **Dependabot updates a dependency**: `.github/dependabot.yml`
  applies weekly to pip and github-actions
  (`.github/dependabot.yml:1-11`); the test matrix catches
  regressions.
- **CodeQL finding**: `.github/workflows/codeql.yml` runs
  matrix on `actions` and `python` (`codeql.yml:18-19`); a
  positive finding requires triage before release.
- **Skill validator regression**:
  `.github/workflows/validate-skills.yml` runs
  `skills-ref` against every bundled skill (`:46-57`).
- **Tag pushed without matching version in `pyproject.toml`**:
  release workflow may still build, but the wheel filename
  will reflect the `pyproject.toml` version, not the tag —
  **(AI suggestion — confirm)**.
- **Network unavailable** at runtime: every catalog read
  resolves via `_locate_bundled_catalog_file`
  (`_bundled_catalogs.py:28-45`); offline guarantee held.
- **Tampered wheel**: detectable by `verify_asset_integrity`
  if invoked; today not invoked at runtime (RDEBT-003).
- **PyPI publication intent**: today only GitHub Releases
  are wired. See **RDEBT-018** / TDEBT-018, TDEBT-019.
- **`uv build` without the build hook on `path`**: the hook
  is wired via `pyproject.toml:29-30`, so it is loaded by
  hatchling automatically. A misconfiguration would surface
  as missing `kiss_cli/core_pack/` in the wheel.

## Requirements

### Functional Requirements

- **FR-001**: The build backend MUST be `hatchling` per
  `pyproject.toml:25-28`.
- **FR-002**: A custom build hook
  (`scripts/hatch_build_hooks.py:104`) MUST be wired in
  `pyproject.toml:29-30` and MUST run at `uv build` time.
- **FR-003**: At build time, the hook MUST: wipe and re-create
  `build/core_pack/`; mirror the five asset trees per
  `ASSET_MAP`; shell out to
  `scripts/generate-checksums.py`; on failure raise
  `RuntimeError("Asset checksum generation failed")`
  (`hatch_build_hooks.py:113-144`).
- **FR-004**: The build hook MUST exclude paths matching
  `.DS_Store`, `__pycache__`, `.pytest_cache`, `*.pyc`,
  `*.pyo`, and any path part starting with `_`
  (`hatch_build_hooks.py:51-71`).
- **FR-005**: The wheel `force-include` MUST map
  `build/core_pack` → `kiss_cli/core_pack`
  (`pyproject.toml:41-42`).
- **FR-006**: The sdist MUST include the repo-root asset
  directories AND exclude `build/`, `__pycache__`,
  `.pytest_cache`, `.DS_Store`, and `*.pyc`
  (`pyproject.toml:44-70`).
- **FR-007**: The runtime asset resolver
  `_locate_core_pack()` MUST find
  `kiss_cli/core_pack/` after install, with a fallback to
  the source-checkout layout when running from a non-
  installed working copy
  (`installer.py:301-315`).
- **FR-008**: All catalog reads MUST go through
  `_locate_bundled_catalog_file()` so that runtime is
  offline-only (`_bundled_catalogs.py:1-12,28-45`).
- **FR-009**: `_integrity.verify_asset_integrity(core_pack_root)`
  MUST verify every file's SHA-256 against
  `core_pack/sha256sums.txt`; on tamper it MUST raise
  `AssetCorruptionError` (`_integrity.py:24-99`). Production
  call site is **RDEBT-003**.
- **FR-010**: The CI test workflow MUST run pytest on the
  matrix `{ubuntu-latest, windows-latest} × {3.11, 3.12,
  3.13}` (`.github/workflows/test.yml:30-55`).
- **FR-011**: The CI lint workflow MUST run Ruff against
  `src/` (`.github/workflows/test.yml:26-27`) and
  `markdownlint-cli2` against project markdown
  (`.github/workflows/lint.yml:17-22`).
- **FR-012**: The CI security workflow (CodeQL) MUST run
  matrix on `actions` and `python`
  (`.github/workflows/codeql.yml:18-19`).
- **FR-013**: The skill-validator workflow MUST run
  `skills-ref` against every bundled skill
  (`.github/workflows/validate-skills.yml:46-57`).
- **FR-014**: The release workflow MUST be tag-triggered,
  build wheel + sdist via `uv build`, compute a
  `SHA256SUMS` file, and attach all three to a GitHub
  Release (`.github/workflows/release.yml:1-141`).
- **FR-015**: The release workflow MUST NOT auto-publish to
  PyPI (ADR-008 / TDEBT-018).
- **FR-016**: The CLI MUST expose `kiss version`
  (`cli/version.py:12-39`) and `kiss --version` /
  `kiss -V` (`cli/__init__.py:24`).
- **FR-017**: `get_kiss_version()` MUST fall back to
  `"unknown"` when both package metadata and
  `pyproject.toml` are unavailable (`version.py:7-23`).
- **FR-018**: The `dependabot.yml` MUST schedule weekly
  updates for pip and github-actions ecosystems
  (`.github/dependabot.yml:1-11`).
- **FR-019**: The `pytest` configuration MUST set
  `testpaths = ["tests"]`, fixed test class/file/function
  naming, and source `coverage` to `["src"]`
  (`pyproject.toml:84-101`).

### Non-Functional Requirements

- **NFR-001 (Offline)**: The runtime MUST not perform
  network I/O once installed (ADR-003,
  `tests/test_offline.py`). The proposed boundary tests
  (ADR-017) extend coverage to every CLI subcommand.
- **NFR-002 (Cross-platform)**: CI covers Linux + Windows
  on Python 3.11 / 3.12 / 3.13. macOS support is asserted
  but not in CI (RDEBT-005 / TDEBT-014).
- **NFR-003 (Shell parity)**: Bash and PowerShell flavours
  ship in every skill; the build hook preserves both
  (ADR-006 / ADR-015).
- **NFR-004 (Coverage)**: ≥ 80 % on changed files; the
  `--cov-fail-under` pin is outstanding (RDEBT-006 /
  TDEBT-015).
- **NFR-005 (Complexity / size)**: Build / runtime
  modules MUST stay ≤ 40 LOC, complexity ≤ 10 (Principle
  III). `hatch_build_hooks.py` is 144 LOC and individual
  functions are within bounds.
- **NFR-006 (Lint)**: Zero Ruff warnings on changed files
  (ADR-016, RDEBT-006).
- **NFR-007 (Reproducibility)**: A wheel built from the
  sdist MUST contain the same `kiss_cli/core_pack/`
  contents as a wheel built from the source tree
  (FR-006 + FR-007 implication).
- **NFR-008 (Asset integrity)**: Wheel ships
  `core_pack/sha256sums.txt`; verification is runnable
  (FR-009).
- **NFR-009 (Performance — qualitative)**: `kiss init`
  completes "within seconds" (RDEBT-002 / TDEBT-017).

### Key Entities

- **`pyproject.toml`** — package metadata, dependencies,
  build hook wiring, sdist + wheel layout
  (`pyproject.toml:1-101`).
- **`scripts/hatch_build_hooks.py`** — `CustomBuildHook`,
  `ASSET_MAP`, exclusion rules.
- **`scripts/generate-checksums.py`** — produces
  `core_pack/sha256sums.txt`.
- **`build/core_pack/`** — gitignored build-time staging.
- **`kiss_cli/core_pack/`** — runtime asset bundle inside
  the installed wheel.
- **`_integrity.py`** — `verify_asset_integrity`,
  `AssetCorruptionError`.
- **`_bundled_catalogs.py`** — offline catalog loader.
- **`installer.py:301-391`** — runtime asset resolver
  (`_locate_core_pack`, `_locate_bundled_extension`,
  `_locate_bundled_workflow`, `_locate_bundled_preset`).
- **`.github/workflows/{test,lint,codeql,release,
  release-trigger,validate-skills,docs,stale}.yml`** —
  CI.
- **`.github/dependabot.yml`** — weekly updates.

## Success Criteria

### Measurable Outcomes

- **SC-001**: Every CI run on every supported matrix cell
  passes pytest + Ruff before any release tag is cut.
- **SC-002**: Every released wheel contains
  `kiss_cli/core_pack/sha256sums.txt` whose entries match
  the hashes of the rest of `core_pack/`.
- **SC-003**: Zero network calls during `kiss init` /
  `kiss integration upgrade` — defended by
  `tests/test_offline.py` (and ADR-017 once that test is
  extended).
- **SC-004**: GitHub Releases attach wheel + sdist +
  `SHA256SUMS` for every tag (`.github/workflows/release.yml`).
- **SC-005**: `kiss version` returns a non-empty version
  string for any installed wheel (or `"unknown"` for an
  installed-from-source case where metadata is absent).

## Assumptions

- The release maintainer pushes a `v*` tag manually after
  reviewing CI; no automatic tagging.
- PyPI publication is NOT wired today; if added later, it
  is via a separate manual workflow per ADR-008
  (TDEBT-018).
- The wheel's installable name (`kiss` per
  `pyproject.toml:2`) may not match the GitHub repo name
  (`kiss-u`); `docs/installation.md` reflects the wheel
  name (TDEBT-019 / RDEBT-018).
- Maintainers run `uv tool install` (or the equivalent) on
  the user's machine; KISS itself does not bootstrap onto
  the machine.
- Direct pushes to `main` are forbidden by the standards'
  Development Workflow.

## Out of Scope

- Hosting kiss as a service. Kiss is distributed software
  only.
- Auto-publish to PyPI on tag (explicitly forbidden by
  ADR-008).
- Building Docker images of kiss.
- Cross-version migration of the asset bundle layout
  (today every kiss release ships its own pinned bundle).
- Self-update of the kiss CLI from within the CLI (the
  user upgrades via `uv tool install --force` per
  `docs/upgrade.md:17-44`).

## Traceability

- **ADRs**: ADR-001 (CLI framework), ADR-002 (Hatch build
  hook), ADR-003 (offline), ADR-007 (asset integrity),
  ADR-008 (tag-triggered releases, no auto-PyPI), ADR-016
  (Ruff config), ADR-017 (offline boundary tests).
- **Source modules**:
  `pyproject.toml:1-101`;
  `scripts/hatch_build_hooks.py:1-144`;
  `scripts/generate-checksums.py:1-71`;
  `src/kiss_cli/installer.py:301-391`;
  `src/kiss_cli/_integrity.py:24-99`;
  `src/kiss_cli/_bundled_catalogs.py:1-64`;
  `src/kiss_cli/cli/version.py:12-39`;
  `src/kiss_cli/version.py:7-23`;
  `src/kiss_cli/cli/__init__.py:11-32`.
- **CI**: `.github/workflows/test.yml`,
  `.github/workflows/lint.yml`,
  `.github/workflows/codeql.yml`,
  `.github/workflows/release.yml`,
  `.github/workflows/release-trigger.yml`,
  `.github/workflows/validate-skills.yml`,
  `.github/workflows/docs.yml`,
  `.github/workflows/stale.yml`,
  `.github/dependabot.yml`.
- **Tests**: `tests/test_offline.py`,
  `tests/test_asset_integrity.py`,
  `tests/test_agent_skills_compliance.py`.
- **Related specs**: every other spec depends on this one
  for the offline-runtime invariant and the bundled-asset
  contract.
- **Related debts**: RDEBT-002 (perf NFR), RDEBT-003
  (asset integrity wiring), RDEBT-005 (macOS),
  RDEBT-006 (coverage), RDEBT-018 (PyPI intent);
  cross-link TDEBT-002, TDEBT-014, TDEBT-015,
  TDEBT-018, TDEBT-019, TDEBT-023.
