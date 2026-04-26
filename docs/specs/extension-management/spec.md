# Feature Specification: extension-management

**Feature Slug**: `extension-management`
**Created**: 2026-04-26
**Status**: Draft (reverse-engineered)
**Mode**: auto
**Input**: `cli/extension.py:84-1205`,
`extensions.py:1-2493`,
`extensions/` (3 bundled extensions: `git/`, `selftest/`,
`template/`),
`docs/architecture/intake.md` §7.2.1.

## Problem Statement

A developer wants to extend kiss with project-specific or shared
"extensions" — small bundles that contribute new slash commands,
hooks (e.g. `before_specify`, `after_specify`), and config — so
that kiss can grow with the team without forking the CLI itself.
They need:

- a way to list, add, remove, search, inspect, update, and
  enable/disable extensions;
- a hook system that lets extensions interpose on `kiss-specify`
  and similar commands without modifying core code;
- a manifest contract so install/remove are diff-aware and safe;
- a community catalog so extensions can be shared.

Source evidence: `src/kiss_cli/cli/extension.py:84-1205` (12
extension commands), `src/kiss_cli/extensions.py:1-2493`
(manifest, registry, manager, catalog, config, hook executor,
frontmatter codec). Three bundled extensions live at
`extensions/git/`, `extensions/selftest/`, `extensions/template/`.

## User Scenarios & Testing

### User Story 1 — Add an extension (Priority: P1)

As a developer wanting to add the bundled `git` extension to
my project (gives me `/kiss.git.feature` and friends), I want
to run `kiss extension add git` and have its commands and
hooks become available immediately, with manifest tracking.

**Why this priority**: Headline value — extensions that don't
install offer no practical benefit.

**Independent test**: Run `kiss extension add git`; confirm
`.kiss/extensions/git/` exists, `extensions.yml` is updated,
and the new slash command resolves in the AI tool.

**Acceptance Scenarios**:

1. **Given** an initialised kiss project, **When** the user
   runs `kiss extension add git`, **Then** the extension's
   files are written under `.kiss/extensions/git/`, an
   extension manifest is recorded, and any registered hooks
   become active (`cli/extension.py:315-420`).
2. **Given** the user passes a path to a local extension
   directory or a `.zip`, **When** the command runs, **Then**
   `install_from_directory` or `install_from_zip` is invoked
   accordingly (per intake §7.2.1).
3. **Given** an unknown extension id, **When** the command
   runs, **Then** the command exits with code `1` and prints
   the available extensions.

### User Story 2 — List installed and catalog extensions (Priority: P1)

As a developer auditing my project, I want to run
`kiss extension list` to see what is installed and
`kiss extension catalog list` to browse what else is
available.

**Acceptance Scenarios**:

1. **Given** one or more extensions installed, **When** the
   user runs `kiss extension list`, **Then** the command
   prints a Rich table of installed extensions with id,
   version, priority, enabled-state
   (`cli/extension.py:100-141`).
2. **Given** any kiss project, **When** the user runs
   `kiss extension catalog list`, **Then** the command prints
   the catalog of available extensions
   (`cli/extension.py:143-200`).

### User Story 3 — Remove an installed extension (Priority: P1)

As a developer no longer needing the `selftest` extension, I
want to run `kiss extension remove selftest` to remove it
cleanly, preserving any file I have modified.

**Acceptance Scenarios**:

1. **Given** an extension is installed, **When** the user
   runs `kiss extension remove <id>`, **Then** the extension's
   files are removed (modified files preserved by default)
   and the registry entry is dropped
   (`cli/extension.py:422-495`).

### User Story 4 — Update an extension diff-aware (Priority: P2)

As a developer running a newer kiss with a refreshed bundled
extension, I want to run `kiss extension update [id]` to
diff-merge the extension's files against my project,
preserving local edits.

**Acceptance Scenarios**:

1. **Given** an extension installed at version `v1.0.0`,
   **When** the user runs `kiss extension update <id>`,
   **Then** the command applies the diff between the new and
   old versions, refusing to overwrite locally-modified files
   unless `--force` is supplied (`cli/extension.py:674-…`).

### User Story 5 — Inspect an extension (Priority: P2)

As a developer evaluating an extension, I want to run
`kiss extension info <id>` to see its description, contributed
commands, hooks, and config schema.

**Acceptance Scenarios**:

1. **Given** a known extension, **When** the user runs
   `kiss extension info <id>`, **Then** the command prints the
   extension's metadata (`cli/extension.py:582-673`).

### User Story 6 — Search the catalog (Priority: P2)

**Acceptance Scenarios**:

1. **Given** the user runs `kiss extension search <q>`,
   **When** the command runs, **Then** it filters catalog
   entries by id / name / description
   (`cli/extension.py:496-581`).

### User Story 7 — Enable / disable an extension (Priority: P3)

As a developer debugging a hook conflict, I want to disable an
extension without removing it.

**Acceptance Scenarios**:

1. **Given** an extension is installed, **When** the user
   runs `kiss extension disable <id>`, **Then** the
   extension's hooks become inactive but its files remain on
   disk (`cli/extension.py:1063-1108,1109-1156`).
2. **Given** the same setup, **When** the user re-enables it,
   **Then** the hooks re-activate.

### User Story 8 — Re-prioritise extensions (Priority: P3)

**Acceptance Scenarios**:

1. **Given** two extensions register conflicting hooks,
   **When** the user runs
   `kiss extension set-priority <id> <N>`, **Then** the
   priority is recorded (`cli/extension.py:1157-1204`) and
   subsequent hook resolution honours the new order.

### User Story 9 — Manage the catalog (Priority: P3)

**Acceptance Scenarios**:

1. **Given** a valid catalog source, **When** the user runs
   `kiss extension catalog add <name> <src>`, **Then** the
   catalog is registered (`cli/extension.py:202-272`).
2. **Given** an existing catalog, **When** the user runs
   `kiss extension catalog remove <name>`, **Then** the
   catalog is deregistered (`cli/extension.py:273-313`).

### Edge Cases

- **`.kiss/` missing**: every extension command requires a
  kiss project; missing `.kiss/` exits with code `1`.
- **Manifest validation failure**: `ValidationError` /
  `CompatibilityError` aborts the install with an error
  message (per intake §7.2.1).
- **Conflicting commands**: two extensions registering the
  same slash command name — resolution is governed by
  priority + the `_load_core_command_names` core-name guard
  (extensions cannot redefine core kiss commands).
- **Hook execution failure**: a failed hook exits with the
  hook's own non-zero code; the parent command surfaces it.
  Default behaviour for hook failure (continue / abort /
  retry) is not fully documented — see **RDEBT-013**.
- **Hook security**: extensions can run arbitrary commands
  via `HookExecutor`. There is no sandbox or confirmation
  prompt today (`extensions.py:2063+`). See **RDEBT-013**.
- **Manifest mismatch on remove**: same default-preserve-
  modified policy as the integration manifest. **(AI
  suggestion — confirm)**.
- **Catalog network access**: catalog refreshes may require
  network. The bundled flow is offline. See **RDEBT-023**.
- **Catalog source signed / verified?**: trust model is
  unstated. See **RDEBT-022**.
- **Network unavailable** (offline guarantee): bundled
  extension install MUST work; community catalog operations
  are best-effort.

## Requirements

### Functional Requirements

- **FR-001**: The CLI MUST expose extension commands:
  `list`, `add <id-or-path>`, `remove <id>`, `search <query>`,
  `info <id>`, `update [<id>]`, `enable <id>`,
  `disable <id>`, `set-priority <id> <N>`
  (`cli/extension.py:100,143,202,273,315,422,496,582,674,
  1063,1109,1157`).
- **FR-002**: The CLI MUST expose catalog commands:
  `kiss extension catalog list`, `add <name> <src>`,
  `remove <name>` (`cli/extension.py:143,202,273`).
- **FR-003**: All extension commands MUST verify the user is
  in a kiss project; missing `.kiss/` MUST exit with code `1`.
- **FR-004**: `add` MUST accept a registered extension id, a
  local directory path, OR a `.zip` archive; the manager MUST
  detect the source type and route to
  `install_from_directory` / `install_from_zip` accordingly
  (per intake §7.2.1).
- **FR-005**: `add` MUST validate the extension's manifest via
  `ExtensionManifest._validate`; failures MUST surface as
  `ValidationError` and abort the install.
- **FR-006**: `add` MUST refuse to install when a
  compatibility rule fails (`CompatibilityError`).
- **FR-007**: `add` MUST refuse to register a slash command
  whose name collides with a core kiss command — enforced via
  `_load_core_command_names` (per intake §7.2.1).
- **FR-008**: `add` MUST hash every written file in a
  per-extension manifest, mirroring ADR-004's contract.
- **FR-009**: `update` MUST be diff-aware: it MUST compare
  manifest hashes, list locally-modified files, and refuse
  to overwrite them unless `--force` is supplied
  (`cli/extension.py:674-…`).
- **FR-010**: `remove` MUST remove the extension's files
  (preserving modified ones by default), drop the registry
  entry, and de-activate its hooks
  (`cli/extension.py:422-495`).
- **FR-011**: `set-priority` MUST update the registered
  priority; `enable`/`disable` MUST toggle the active flag.
- **FR-012**: `list` MUST render a Rich table of installed
  extensions; `info <id>` MUST render full metadata.
- **FR-013**: `search <query>` MUST search across catalog
  entries by id / name / description.
- **FR-014**: Hook execution MUST go through `HookExecutor`,
  which is the only module allowed to invoke `subprocess`
  inside the extensions package (Principle IV / ADR-013).
- **FR-015**: Bundled extension install MUST NOT perform
  network I/O — assets resolve via
  `_locate_bundled_extension` (`installer.py:318-340`).
  Community catalog operations may require network — see
  **RDEBT-023**.

### Non-Functional Requirements

- **NFR-001 (Offline)**: Bundled extension operations MUST not
  perform network I/O (ADR-003).
- **NFR-002 (Cross-platform)**: Linux, Windows; macOS
  asserted (RDEBT-005).
- **NFR-003 (Shell parity)**: Each extension's bundled hooks
  / commands MUST ship both `scripts/bash/` and
  `scripts/powershell/` flavours when both exist (ADR-006 /
  ADR-015).
- **NFR-004 (Coverage)**: ≥ 80 % on changed files
  (RDEBT-006).
- **NFR-005 (Complexity / size)**: ≤ 40 LOC, complexity ≤ 10,
  nesting ≤ 3 — current `extensions.py` is 2,493 LOC and
  violates this; ADR-013 is the planned decomposition
  (RDEBT-007 / TDEBT-003).
- **NFR-006 (Lint)**: Zero Ruff warnings on changed files
  (ADR-016).
- **NFR-007 (I/O boundary)**: I/O MUST be isolated to
  `manifest.py`, `registry.py`, `catalog.py`, `config.py`,
  `core_commands.py`, and `hooks.py`; `version.py`,
  `frontmatter.py`, and `_validate` portions of `manifest.py`
  MUST be pure (Principle IV / ADR-013).
- **NFR-008 (Manifest contract)**: Every install / update /
  remove MUST go through the SHA-256 manifest contract
  (ADR-004 analogue).

### Key Entities

- **`ExtensionManifest`** — `extensions.py:174-390`. Loads
  and validates `extension.yml`.
- **`ExtensionRegistry`** — `extensions.py:391-627`. Tracks
  installed extensions in `.kiss/extensions/registry.json`.
- **`ExtensionManager`** — `extensions.py:628-1420`. The
  install / update / remove orchestrator.
- **`ExtensionCatalog`** — `extensions.py:1524-1864`.
- **`ConfigManager`** — `extensions.py:1865-2062`. Per-
  extension config files.
- **`HookExecutor`** — `extensions.py:2063+`. The only place
  inside the extensions package that shells out (Principle
  IV / ADR-013).
- **`CommandRegistrar` (local)** —
  `extensions.py:1439-1523`. Frontmatter parse + render.
  *Note:* this collides with `kiss_cli.agents.CommandRegistrar`;
  ADR-013 + TDEBT-020 propose a rename to `FrontmatterCodec`.
- **`CatalogEntry`** — dataclass.
- **Exceptions**: `ExtensionError`, `ValidationError`,
  `CompatibilityError`.
- **`.kiss/extensions/registry.json`** — installed-extension
  state.
- **`.kiss/extensions.yml`** — hook configuration consulted
  by core commands (e.g. `kiss-specify` reads
  `hooks.before_specify`).

## Success Criteria

### Measurable Outcomes

- **SC-001**: `kiss extension add <id>` followed by
  `kiss extension list` shows `<id>` as installed 100 % of
  the time across the three bundled extensions.
- **SC-002**: After `kiss extension remove <id>`, every file
  recorded in the install manifest is either removed or
  preserved-because-modified.
- **SC-003**: A registered hook fires at the documented
  `before_specify` / `after_specify` boundaries, verifiable
  by a test extension.
- **SC-004**: Bundled extension install performs zero network
  I/O — defended by the offline test suite (extended per
  ADR-017).
- **SC-005**: `update` never silently overwrites a locally-
  modified file (modified files are listed before any write).

## Assumptions

- The user has run `kiss init` so `.kiss/` exists.
- Extension authors honour the schema validated by
  `ExtensionManifest._validate`.
- Hooks run in the user's shell with the user's permissions —
  there is no privilege isolation. The user is expected to
  trust extensions they install (RDEBT-013).
- Priority is an integer where lower means earlier.
  **(AI suggestion — confirm.)**

## Out of Scope

- Authoring new extensions (developer / contributor work; see
  `extensions/template/` for the scaffold).
- Sandboxing or signing extension hooks (RDEBT-013).
- Migrating extension manifests across kiss versions.
- Hosting a public extension catalog server / registry.
- Cross-extension orchestration (chain of hooks across
  unrelated extensions) — today, hook ordering is by
  priority within a single hook key.

## Traceability

- **ADRs**: ADR-003 (offline), ADR-004 (manifests analogue),
  ADR-006 (parity), ADR-013 (`extensions.py` decomposition),
  ADR-015 (parity invariant).
- **Source modules**:
  `src/kiss_cli/cli/extension.py:84-1205` (12 commands);
  `src/kiss_cli/extensions.py:1-2493` (manager etc.);
  `src/kiss_cli/installer.py:318-340` (bundled extension
  locator).
- **Tests**: `tests/test_extensions.py`.
- **Bundled assets**: `extensions/git/extension.yml`,
  `extensions/selftest/extension.yml`,
  `extensions/template/extension.yml`.
- **Related specs**: `preset-management/spec.md`,
  `workflow-engine/spec.md`,
  `integration-system/spec.md`,
  `kiss-init/spec.md` (auto-installs the bundled `git`
  extension).
- **Related debts**: RDEBT-005, RDEBT-006, RDEBT-007,
  RDEBT-013 (hook security), RDEBT-022 (catalog trust),
  RDEBT-023 (catalog network); cross-link TDEBT-003 and
  TDEBT-020.
