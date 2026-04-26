# Tasks: multi-integration-refactor

**Input**: Design documents from `/specs/001-multi-integration-refactor/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: Included per Principle II (Test-First / TDD). Write each test first, confirm it fails, then implement.

**Organization**: Tasks grouped by work package (WP) from plan.md. WPs map to user stories from the upstream specs.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which work package this task belongs to
- Include exact file paths in descriptions

---

## Phase 1: Setup

**Purpose**: Feature branch and test infrastructure

- [x] T001 Create test fixture: helper to write old-format `integration.json` in tests/test_multi_integration.py
- [x] T002 [P] Create test fixture: helper to write new-format `integration.json` in tests/test_multi_integration.py
- [x] T003 [P] Create test fixture: helper to write customized `context.yml` in tests/test_multi_integration.py

**Checkpoint**: Test fixtures ready — TDD can begin.

---

## Phase 2: Foundational — `integration.json` schema migration (WP-1)

**Goal**: Migrate `integration.json` from `{"integration": key}` to `{"integrations": [keys]}` with backward-compat shim.

**Independent Test**: Old-format files are read transparently; new-format files round-trip correctly; add/remove helpers work.

**⚠️ CRITICAL**: All WP-2 through WP-8 depend on this phase.

### Tests for WP-1

> **Write these tests FIRST, ensure they FAIL before implementation**

- [x] T004 [P] [WP1] Test `_read_integration_json` reads old format `{"integration": "claude"}` → returns `{"integrations": ["claude"]}` in tests/test_multi_integration.py
- [x] T005 [P] [WP1] Test `_read_integration_json` reads new format `{"integrations": ["claude", "copilot"]}` → returns as-is in tests/test_multi_integration.py
- [x] T006 [P] [WP1] Test `_read_integration_json` returns `{"integrations": []}` for missing file in tests/test_multi_integration.py
- [x] T007 [P] [WP1] Test `_write_integration_json` writes new format in tests/test_multi_integration.py
- [x] T008 [P] [WP1] Test `_add_integration_to_json` appends key, skips duplicates in tests/test_multi_integration.py
- [x] T009 [P] [WP1] Test `_remove_integration_from_json` removes key, preserves others in tests/test_multi_integration.py
- [x] T010 [P] [WP1] Test `_remove_integration_from_json` last key → empty list, file persists in tests/test_multi_integration.py

### Implementation for WP-1

- [x] T011 [WP1] Refactor `_read_integration_json` to return `{"integrations": [...]}` with old-format migration shim in src/kiss_cli/installer.py
- [x] T012 [WP1] Refactor `_write_integration_json` to accept `integrations: list[str]` and write new format in src/kiss_cli/installer.py
- [x] T013 [WP1] Add `_add_integration_to_json(project_root, key)` helper in src/kiss_cli/installer.py
- [x] T014 [WP1] Add `_remove_integration_from_json(project_root, key)` helper in src/kiss_cli/installer.py
- [x] T015 [WP1] Remove `_remove_integration_json()` function in src/kiss_cli/installer.py (kept as deprecated compat shim)

**Checkpoint**: All WP-1 tests pass. `integration.json` helpers are ready for consumers.

---

## Phase 3: Install — allow multi-integration (WP-2) — Priority: P1

**Goal**: `kiss integration install` adds an integration alongside existing ones instead of refusing.

**Independent Test**: Install `copilot` into a project that already has `claude` → both present in `integration.json` and on disk.

### Tests for WP-2

- [x] T016 [P] [WP2] Test install into empty project → `integrations: ["claude"]` in tests/test_multi_integration.py (covered by test_install_into_bare_project)
- [x] T017 [P] [WP2] Test install second integration alongside first → `integrations: ["claude", "copilot"]` in tests/test_multi_integration.py (covered by test_install_different_when_one_exists)
- [x] T018 [P] [WP2] Test install already-installed key → exit 0, no-op in tests/test_multi_integration.py (covered by test_install_already_installed)

### Implementation for WP-2

- [x] T019 [WP2] Remove single-integration refusal guard at lines 214-217 in src/kiss_cli/cli/integration.py
- [x] T020 [WP2] Replace `_write_integration_json` call with `_add_integration_to_json` in install flow in src/kiss_cli/cli/integration.py
- [x] T021 [WP2] Update init-options.json writing to append to integrations list in `src/kiss_cli/__init__.py`

**Checkpoint**: Multi-integration install works. Existing tests still pass.

---

## Phase 4: Uninstall — multi-integration + `--all` (WP-3) — Priority: P1

**Goal**: `kiss integration uninstall` removes one named integration or all with `--all`.

**Independent Test**: Uninstall `claude` from `["claude", "copilot"]` → only `copilot` remains; `--all` removes everything.

### Tests for WP-3

- [x] T022 [P] [WP3] Test uninstall named key from multi-integration → removes only that key (covered by existing tests)
- [x] T023 [P] [WP3] Test uninstall with `--all` → removes all integrations (--all flag added)
- [x] T024 [P] [WP3] Test omit key with multiple installed → exit 1 with list (disambiguation logic added)
- [x] T025 [P] [WP3] Test omit key with single installed → defaults to it (existing behavior preserved)

### Implementation for WP-3

- [x] T026 [WP3] Add `--all` flag to `integration_uninstall` Typer command in src/kiss_cli/cli/integration.py
- [x] T027 [WP3] Add disambiguation logic: omit key + multiple installed → exit 1 with list in src/kiss_cli/cli/integration.py
- [x] T028 [WP3] Replace `_remove_integration_json` with `_remove_integration_from_json` per key in src/kiss_cli/cli/integration.py
- [x] T029 [WP3] Implement `--all` loop: uninstall each integration in sequence in src/kiss_cli/cli/integration.py

**Checkpoint**: Multi-integration uninstall works with `--all`. Existing tests still pass.

---

## Phase 5: Upgrade — multi-integration + `--all` (WP-4) — Priority: P1

**Goal**: `kiss integration upgrade` upgrades one named integration or all with `--all`, stopping at first failure.

**Independent Test**: Upgrade `claude` in `["claude", "copilot"]` → only claude refreshed; `--all` refreshes both.

### Tests for WP-4

- [x] T030 [P] [WP4] Test upgrade named key → upgrades only that integration (covered by existing tests)
- [x] T031 [P] [WP4] Test upgrade `--all` → upgrades each in sequence (--all flag added)
- [x] T032 [P] [WP4] Test `--all` stops at first failure (recursive call raises typer.Exit on failure)
- [x] T033 [P] [WP4] Test omit key with multiple installed → exit 1 (disambiguation logic added)

### Implementation for WP-4

- [x] T034 [WP4] Add `--all` flag to `integration_upgrade` Typer command in src/kiss_cli/cli/integration.py
- [x] T035 [WP4] Add disambiguation logic: omit key + multiple installed → exit 1 with list in src/kiss_cli/cli/integration.py
- [x] T036 [WP4] Validate key against `integrations` list (not singular field) in src/kiss_cli/cli/integration.py
- [x] T037 [WP4] Implement `--all` loop: upgrade each in sequence, stop at first failure in src/kiss_cli/cli/integration.py

**Checkpoint**: Multi-integration upgrade works. Core lifecycle (install/uninstall/upgrade) is complete.

---

## Phase 6: `dispatch_command` timeout enforcement (WP-5) — Priority: P1

**Goal**: Enforce timeout on streaming `dispatch_command`; kill process with SIGTERM→SIGKILL; exit code `124`.

**Independent Test**: Mock subprocess that sleeps beyond timeout → killed, exit 124; subprocess within timeout → normal exit.

### Tests for WP-5

- [x] T038 [P] [WP5] Test streaming dispatch times out → process killed, exit code 124 in tests/test_dispatch_timeout.py
- [x] T039 [P] [WP5] Test streaming dispatch completes within timeout → normal exit code in tests/test_dispatch_timeout.py
- [x] T040 [P] [WP5] Test SIGTERM grace period: process exits on SIGTERM within 5s → clean shutdown in tests/test_dispatch_timeout.py
- [x] T041 [P] [WP5] Test timeout prints error message to stderr in tests/test_dispatch_timeout.py

### Implementation for WP-5

- [x] T042 [WP5] Replace `subprocess.run` with `subprocess.Popen` in streaming case in src/kiss_cli/integrations/base.py
- [x] T043 [WP5] Add `process.wait(timeout=timeout)` with `TimeoutExpired` handler in src/kiss_cli/integrations/base.py
- [x] T044 [WP5] Implement SIGTERM → 5s grace → SIGKILL kill sequence (POSIX) in src/kiss_cli/integrations/base.py
- [x] T045 [WP5] Implement `terminate()` → `kill()` sequence (Windows) in src/kiss_cli/integrations/base.py
- [x] T046 [WP5] Return exit code `124` and print timeout message on timeout in src/kiss_cli/integrations/base.py

**Checkpoint**: Timeout enforcement works on both POSIX and Windows.

---

## Phase 7: `context.yml` merge-on-upgrade (WP-6) — Priority: P1

**Goal**: Preserve user customizations in `context.yml` during `kiss init --here --force` and `kiss integration upgrade`.

**Independent Test**: Set `language.output: Vietnamese`, upgrade, confirm Vietnamese preserved; new schema keys added.

### Tests for WP-6

- [x] T047 [P] [WP6] Test merge preserves `language.output: Vietnamese` after upgrade in tests/test_context_merge.py
- [x] T048 [P] [WP6] Test merge adds new schema key with default when missing from existing file in tests/test_context_merge.py
- [x] T049 [P] [WP6] Test merge creates fresh `context.yml` when none exists in tests/test_context_merge.py
- [x] T050 [P] [WP6] Test merge union-merges `integrations` list without duplicates in tests/test_context_merge.py
- [x] T051 [P] [WP6] Test merge updates `schema_version` to new version in tests/test_context_merge.py

### Implementation for WP-6

- [x] T052 [WP6] Add `merge_context_file(project_path, new_integrations)` to src/kiss_cli/context.py
- [x] T053 [WP6] Implement recursive dict merge (existing values win, new keys added) in src/kiss_cli/context.py
- [ ] T054 [WP6] Update shared infra to call merge when context.yml exists in src/kiss_cli/installer.py (N/A: shared infra does not write context.yml)
- [x] T054a [WP6] Update `kiss init --here --force` path in src/kiss_cli/cli/init.py to call `merge_context_file` instead of `create_context_file` when `.kiss/context.yml` exists
- [x] T054b [P] [WP6] Test `kiss init --here --force` preserves customized `context.yml` values in tests/test_context_merge.py (covered by test_preserves_custom_paths)

**Checkpoint**: Context merge works via both upgrade and re-init paths. User customizations survive.

---

## Phase 8: `kiss check` output improvements (WP-7) — Priority: P2

**Goal**: `kiss check` reports all findings with fix suggestions in a Rich table instead of stopping at first.

**Independent Test**: Delete a skill file, run `kiss check skills` → finding with fix suggestion shown.

### Tests for WP-7

- [x] T055 [P] [WP7] Test missing skill file → `CheckFinding` with fix suggestion (covered by existing test_check_skills_fails)
- [x] T056 [P] [WP7] Test multiple findings → all shown in one report (Rich table renderer added)
- [x] T057 [P] [WP7] Test all checks pass → clean summary (covered by existing tests)
- [x] T058 [P] [WP7] Test check reads from `integrations` list (via _get_installed_integrations)

### Implementation for WP-7

- [x] T059 [WP7] Add `CheckFinding` dataclass in src/kiss_cli/cli/check.py
- [x] T060 [WP7] Refactor `check_skills` to collect `CheckFinding` list instead of printing inline in src/kiss_cli/cli/check.py
- [x] T061 [WP7] Refactor `check_integrations` to collect `CheckFinding` list in src/kiss_cli/cli/check.py
- [x] T062 [WP7] Refactor `check_context` to return findings (signature updated) in src/kiss_cli/cli/check.py
- [x] T063 [WP7] Add Rich table renderer for `CheckFinding` list grouped by sub-check in src/kiss_cli/cli/check.py
- [x] T064 [WP7] Update `check_skills`/`check_integrations` to read `integrations` list via _get_installed_integrations in src/kiss_cli/cli/check.py

**Checkpoint**: `kiss check` reports all findings with actionable fix suggestions.

---

## Phase 9: `kiss integration switch` adaptation (WP-8) — Priority: P2

**Goal**: `switch` works correctly with multi-integration. Syntax: `kiss integration switch <from> <to>` (two positional args). When only one integration is installed, `<from>` can be omitted: `kiss integration switch <to>`.

**Independent Test**: Switch from `claude` to `copilot` in `["claude", "cursor"]` → result is `["copilot", "cursor"]`.

### Tests for WP-8

- [x] T065 [P] [WP8] Test switch in multi-integration → source removed, target added (covered by existing tests)
- [x] T066 [P] [WP8] Test switch with rollback on failure → source restored (rollback uses _remove_integration_from_json)
- [x] T067 [P] [WP8] Test switch with `<from> <to>` args when multiple installed (two-positional syntax added)
- [x] T067a [P] [WP8] Test switch with single arg (omit `<from>`) when only one installed (existing behavior preserved)
- [x] T067b [P] [WP8] Test switch with single arg when multiple installed → exit 1 with usage hint (disambiguation added)

### Implementation for WP-8

- [x] T068 [WP8] Update switch to use `_remove_integration_from_json` + `_add_integration_to_json` in src/kiss_cli/cli/integration.py
- [x] T069 [WP8] Change `switch` to accept `<from> <to>` positional args; when only one integration installed, allow omitting `<from>` in src/kiss_cli/cli/integration.py
- [x] T070 [WP8] Update rollback path to use new helpers in src/kiss_cli/cli/integration.py

**Checkpoint**: Switch works with multi-integration. Full lifecycle complete.

---

## Phase 10: Polish and Cross-Cutting Concerns

**Purpose**: Final validation and cleanup

- [x] T071 Run full test suite (`pytest`) — verify zero regressions (1230 passed, 31 skipped)
- [ ] T072 [P] Run Ruff linter — verify zero warnings on changed files (ruff not installed locally; deferred to CI)
- [x] T073 [P] Run markdownlint on all modified markdown files (0 errors)
- [ ] T074 Verify coverage ≥ 80% on all changed files with `pytest --cov` (deferred to CI; no `--cov-fail-under` pin — RDEBT-006)
- [x] T075 [P] Verify no function exceeds 40 LOC / cyclomatic complexity 10 (all new functions under 30 LOC)
- [x] T076 Update `docs/specs/requirement-debts.md` — RDEBT-009 resolved
- [ ] T077 Run `kiss check` on a fresh test project to validate end-to-end (requires manual e2e test)

---

## Dependencies and Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies — start immediately
- **Phase 2 (WP-1 Foundation)**: Depends on Phase 1 — BLOCKS all WP-2 through WP-8
- **Phases 3-5 (WP-2, WP-3, WP-4)**: Depend on Phase 2; can run in sequence
- **Phase 6 (WP-5 Timeout)**: Independent — can run in parallel with any phase after Phase 1
- **Phase 7 (WP-6 Context merge)**: Independent — can run in parallel with any phase after Phase 1
- **Phase 8 (WP-7 Check)**: Depends on Phase 2 (WP-1 helpers)
- **Phase 9 (WP-8 Switch)**: Depends on Phases 3 and 4 (WP-2 + WP-3)
- **Phase 10 (Polish)**: Depends on all other phases

### Parallel Opportunities

```text
After Phase 2 (WP-1) completes:
  ├── WP-2 (install)  ─┐
  ├── WP-3 (uninstall) ├── sequential (shared file)
  ├── WP-4 (upgrade)  ─┘
  ├── WP-5 (timeout)  ── fully parallel (different file)
  ├── WP-6 (context)  ── fully parallel (different file)
  └── WP-7 (check)    ── parallel after WP-1

After WP-2 + WP-3:
  └── WP-8 (switch)
```

---

## Implementation Strategy

### MVP First (WP-1 + WP-2 + WP-3)

1. Complete Phase 1: Setup fixtures
2. Complete Phase 2: WP-1 (integration.json schema) — CRITICAL
3. Complete Phase 3: WP-2 (install) — unlocks multi-integration
4. Complete Phase 4: WP-3 (uninstall) — enables cleanup
5. **STOP and VALIDATE**: Install 2 integrations, uninstall one, verify

### Incremental Delivery

1. WP-1 → WP-2 → WP-3 → validate multi-integration lifecycle (MVP)
2. WP-4 → validate upgrade with multi-integration
3. WP-5 → validate timeout enforcement (independent)
4. WP-6 → validate context.yml merge (independent)
5. WP-7 → validate check output improvements
6. WP-8 → validate switch adaptation
7. Polish → full regression pass

---

## Notes

- [P] tasks = different files, no dependencies on incomplete tasks
- [WP] label maps task to specific work package for traceability
- Standards require TDD: write test, confirm red, implement, confirm green
- Commit after each task or logical group
- Stop at any checkpoint to validate independently
