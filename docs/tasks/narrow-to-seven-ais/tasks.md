# Tasks: narrow-to-seven-ais

**Input**: Design documents from `/specs/004-narrow-to-seven-ais/`
**Prerequisites**: plan.md, spec.md

**Tests**: TDD per Principle II. Verify existing tests pass after each deletion phase; add new test for asset integrity.

**Organization**: 6 work packages. WP-1/2/3/4 are sequential (source cleanup). WP-5 (docs) and WP-6 (integrity) are independent.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[US]**: Which user story this task belongs to
- Include exact file paths in descriptions

---

## Phase 1: Setup — Inventory and backup

**Purpose**: Confirm all references before deleting anything.

- [ ] T001 Run `grep -rl "agy\|auggie\|kilocode\|kiro\|tabnine\|generic" src/kiss_cli/ tests/` to inventory all references
- [ ] T002 Run full test suite to establish baseline pass count

**Checkpoint**: Baseline recorded. Ready to delete.

---

## Phase 2: US-1 — Remove integration packages + update registry (WP-1 + WP-2)

**Goal**: Delete 6 integration package directories and update the registry to only register 7 AIs.

**Independent Test**: `from kiss_cli.integrations import INTEGRATION_REGISTRY; assert len(INTEGRATION_REGISTRY) == 7`

- [ ] T003 [US1] Delete `src/kiss_cli/integrations/agy/` directory
- [ ] T004 [P] [US1] Delete `src/kiss_cli/integrations/auggie/` directory
- [ ] T005 [P] [US1] Delete `src/kiss_cli/integrations/generic/` directory
- [ ] T006 [P] [US1] Delete `src/kiss_cli/integrations/kilocode/` directory
- [ ] T007 [P] [US1] Delete `src/kiss_cli/integrations/kiro_cli/` directory
- [ ] T008 [P] [US1] Delete `src/kiss_cli/integrations/tabnine/` directory
- [ ] T009 [US1] Update `_register_builtins()` in `src/kiss_cli/integrations/__init__.py` to import and register only 7 supported integrations
- [ ] T010 [US1] Run test to verify `len(INTEGRATION_REGISTRY) == 7`

**Checkpoint**: Only 7 integration packages remain. Registry loads cleanly.

---

## Phase 3: US-2 — Remove tests for deleted integrations (WP-3)

**Goal**: Delete test files for removed integrations and update remaining tests.

- [ ] T011 [US2] Delete `tests/integrations/test_integration_agy.py`
- [ ] T012 [P] [US2] Delete `tests/integrations/test_integration_auggie.py`
- [ ] T013 [P] [US2] Delete `tests/integrations/test_integration_generic.py`
- [ ] T014 [P] [US2] Delete `tests/integrations/test_integration_kilocode.py`
- [ ] T015 [P] [US2] Delete `tests/integrations/test_integration_kiro_cli.py`
- [ ] T016 [P] [US2] Delete `tests/integrations/test_integration_tabnine.py`
- [ ] T017 [US2] Update `tests/integrations/test_registry.py` to expect exactly 7 registrations
- [ ] T018 [US2] Update `tests/integrations/test_integration_subcommand.py` to remove references to deleted integrations
- [ ] T019 [US2] Update `tests/integrations/test_o2_capability_gating.py` to remove references to deleted integrations
- [ ] T020 [US2] Update `tests/test_check_tool.py` to remove kiro-cli special-case test
- [ ] T021 [US2] Update `tests/test_extensions.py` to remove references to deleted integrations
- [ ] T022 [US2] Update `tests/test_presets.py` to remove references to deleted integrations
- [ ] T023 [US2] Run full test suite to verify zero regressions

**Checkpoint**: All tests pass with only 7 supported integrations.

---

## Phase 4: US-5 — Clean source references (WP-4)

**Goal**: Remove all remaining source-code references to deleted integrations.

- [ ] T024 [US5] Remove `tabnine` from `_TOML_AGENTS` in `src/kiss_cli/__init__.py`
- [ ] T025 [P] [US5] Remove `kiro-cli` special case from `check_tool()` in `src/kiss_cli/installer.py`
- [ ] T026 [P] [US5] Remove 6 deleted entries from `INTEGRATION_INSTALL_DIRS` in `src/kiss_cli/cli/check.py`
- [ ] T027 [P] [US5] Remove references to deleted integrations in `src/kiss_cli/agents.py` (if any)
- [ ] T028 [P] [US5] Remove references to deleted integrations in `src/kiss_cli/presets.py` (if any)
- [ ] T029 [P] [US5] Remove references to deleted integrations in `src/kiss_cli/integrations/base.py` (if any)
- [ ] T030 [US5] Run `grep -r "agy\|auggie\|kilocode\|kiro\|tabnine" src/kiss_cli/` to verify zero hits (excluding comments)
- [ ] T031 [US5] Run full test suite to verify zero regressions

**Checkpoint**: Source tree is clean. No references to removed integrations.

---

## Phase 5: US-3 — Clean catalog and docs (WP-5)

**Goal**: Update catalog.json and all documentation to only reference 7 AIs.

- [ ] T032 [US3] Update `integrations/catalog.json` to contain only 7 entries (remove kiro-cli, auggie, tabnine, kilocode, agy, generic)
- [ ] T033 [P] [US3] Update `docs/specs/integration-system/spec.md` to remove references to removed integrations
- [ ] T034 [P] [US3] Update `docs/specs/kiss-init/spec.md` to remove references to removed integrations
- [ ] T035 [P] [US3] Update `docs/specs/kiss-install/spec.md` to remove references to removed integrations
- [ ] T036 [P] [US3] Update `docs/specs/agent-skills-system/spec.md` to remove references to removed integrations
- [ ] T037 [P] [US3] Update `docs/specs/subagent-system/spec.md` to remove references to removed integrations
- [ ] T038 [P] [US3] Update `docs/specs/requirement-debts.md`: resolve RDEBT-004 and RDEBT-024 as completed
- [ ] T039 [P] [US3] Update `docs/upgrade.md` to note that removed integrations require migration
- [ ] T040 [P] [US3] Update `docs/installation.md` to list only 7 supported AIs
- [ ] T041 [P] [US3] Update `docs/reference/integrations.md` to list only 7 supported AIs
- [ ] T042 [P] [US3] Update `docs/architecture/extracted.md` to reflect 7 supported AIs
- [ ] T043 [P] [US3] Update `docs/decisions/ADR-018-narrow-integration-scope-to-seven-ais.md` status from Proposed to Accepted
- [ ] T044 [US3] Run markdownlint on all modified doc files

**Checkpoint**: All docs and catalog reference only 7 AIs.

---

## Phase 6: US-4 — Wire asset integrity verification (WP-6)

**Goal**: `kiss init` and `kiss integration upgrade` call `verify_asset_integrity` before reading the bundle.

### Tests for US-4

- [ ] T045 [P] [US4] Test that `verify_asset_integrity` is called during init in tests/test_asset_integrity.py
- [ ] T046 [P] [US4] Test that `AssetCorruptionError` aborts init with error message in tests/test_asset_integrity.py

### Implementation for US-4

- [ ] T047 [US4] Add `verify_asset_integrity(core_pack_root)` call in `src/kiss_cli/cli/init.py` after `_locate_core_pack`
- [ ] T048 [US4] Add `verify_asset_integrity(core_pack_root)` call in `src/kiss_cli/cli/integration.py` upgrade path
- [ ] T049 [US4] Update `docs/specs/requirement-debts.md`: resolve RDEBT-003 as completed
- [ ] T050 [US4] Run full test suite to verify zero regressions

**Checkpoint**: Asset integrity is verified at runtime. RDEBT-003 resolved.

---

## Phase 7: Polish

- [ ] T051 Run full test suite — verify zero regressions
- [ ] T052 [P] Run markdownlint on all modified files
- [ ] T053 [P] Verify `grep -r "agy\|auggie\|kilocode\|kiro\|tabnine" src/ tests/` returns zero hits
- [ ] T054 Verify `INTEGRATION_REGISTRY` contains exactly 7 keys
- [ ] T055 Verify `integrations/catalog.json` contains exactly 7 entries

---

## Dependencies and Execution Order

- **Phase 1 (Setup)**: No dependencies
- **Phase 2 (US-1 Remove packages)**: Depends on Phase 1
- **Phase 3 (US-2 Remove tests)**: Depends on Phase 2
- **Phase 4 (US-5 Clean source)**: Depends on Phase 2
- **Phase 5 (US-3 Clean docs)**: Independent — can run in parallel with Phase 3/4
- **Phase 6 (US-4 Asset integrity)**: Independent — can run in parallel with any phase
- **Phase 7 (Polish)**: Depends on all

### Parallel Opportunities

```text
After Phase 2:
  ├── Phase 3 (tests)     ─┐
  ├── Phase 4 (source)     ├── sequential (shared test suite)
  ├── Phase 5 (docs)       ── fully parallel (different files)
  └── Phase 6 (integrity)  ── fully parallel (different files)
```

---

## Implementation Strategy

### MVP First (US-1 + US-2)

1. Phase 1: Inventory
2. Phase 2: Remove packages + update registry
3. Phase 3: Remove tests
4. **STOP and VALIDATE**: All tests pass with 7 integrations only
5. Phase 4-6: Clean source, docs, wire integrity
6. Phase 7: Polish
