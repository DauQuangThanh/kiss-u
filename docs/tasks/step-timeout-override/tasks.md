# Tasks: step-timeout-override

**Input**: Design documents from `/specs/002-step-timeout-override/`
**Prerequisites**: plan.md, spec.md

**Tests**: Included per Principle II (Test-First / TDD).

**Organization**: Two independent work packages (WP-1: command step, WP-2: shell step) that can run in parallel.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[US]**: Which user story this task belongs to
- Include exact file paths in descriptions

---

## Phase 1: Setup

**Purpose**: Create test file

- [x] T001 Create test file `tests/test_step_timeout.py` with fixtures for command and shell step contexts

**Checkpoint**: Test infrastructure ready.

---

## Phase 2: User Story 1 — Command step timeout override (P1)

**Goal**: Workflow authors can set `timeout: 1800` on a `command` step.

**Independent Test**: A command step with `timeout: 1800` passes that value to `dispatch_command`.

### Tests for US-1

- [x] T002 [P] [US1] Test command step with `timeout: 1800` in config passes `timeout=1800` to `dispatch_command` in tests/test_step_timeout.py
- [x] T003 [P] [US1] Test command step without `timeout` in config uses default `600` in tests/test_step_timeout.py

### Implementation for US-1

- [x] T004 [US1] Read `config.get("timeout", 600)` and pass to `dispatch_command(timeout=...)` in `src/kiss_cli/workflows/steps/command/__init__.py`

**Checkpoint**: Command step timeout override works.

---

## Phase 3: User Story 2 — Shell step timeout override (P1)

**Goal**: Workflow authors can set `timeout: 60` on a `shell` step.

**Independent Test**: A shell step with `timeout: 60` passes that value to `subprocess.run`.

### Tests for US-2

- [x] T005 [P] [US2] Test shell step with `timeout: 60` in config uses `timeout=60` for subprocess in tests/test_step_timeout.py
- [x] T006 [P] [US2] Test shell step without `timeout` in config uses default `300` in tests/test_step_timeout.py
- [x] T007 [P] [US2] Test shell step timeout error message shows actual timeout value in tests/test_step_timeout.py

### Implementation for US-2

- [x] T008 [US2] Replace hard-coded `timeout=300` with `config.get("timeout", 300)` in `src/kiss_cli/workflows/steps/shell/__init__.py`
- [x] T009 [US2] Update timeout error message to use actual value in `src/kiss_cli/workflows/steps/shell/__init__.py`

**Checkpoint**: Shell step timeout override works.

---

## Phase 4: User Story 3 — Validation (P2)

**Goal**: Invalid timeout values are caught at validation time.

**Independent Test**: `timeout: -1` and `timeout: "fast"` produce validation errors.

### Tests for US-3

- [x] T010 [P] [US3] Test command step `validate` rejects `timeout: -1` in tests/test_step_timeout.py
- [x] T011 [P] [US3] Test command step `validate` rejects `timeout: "fast"` in tests/test_step_timeout.py
- [x] T012 [P] [US3] Test shell step `validate` rejects `timeout: 0` in tests/test_step_timeout.py
- [x] T013 [P] [US3] Test both steps `validate` accept valid `timeout: 1800` in tests/test_step_timeout.py

### Implementation for US-3

- [x] T014 [US3] Add timeout validation to `CommandStep.validate` in `src/kiss_cli/workflows/steps/command/__init__.py`
- [x] T015 [US3] Add timeout validation to `ShellStep.validate` in `src/kiss_cli/workflows/steps/shell/__init__.py`

**Checkpoint**: Invalid timeout values rejected at validation time.

---

## Phase 5: Polish

- [x] T016 Run full test suite — verify zero regressions (1239 passed, 31 skipped)
- [x] T017 [P] Run markdownlint on modified markdown files (0 errors)
- [x] T018 [P] Verify no function exceeds 40 LOC (all changes under 10 LOC per function)

---

## Dependencies and Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies
- **Phase 2 (US-1 Command)**: Depends on Phase 1
- **Phase 3 (US-2 Shell)**: Depends on Phase 1; independent of Phase 2
- **Phase 4 (US-3 Validation)**: Depends on Phases 2 and 3
- **Phase 5 (Polish)**: Depends on all other phases

### Parallel Opportunities

```text
After Phase 1:
  ├── US-1 (command step)  ── fully parallel
  └── US-2 (shell step)    ── fully parallel

After US-1 + US-2:
  └── US-3 (validation)
```

---

## Implementation Strategy

### MVP First (US-1 + US-2)

1. Phase 1: Create test file
2. Phase 2 + 3 in parallel: Command + Shell timeout override
3. **STOP and VALIDATE**: Both steps read timeout from config
4. Phase 4: Validation
5. Phase 5: Polish

---

## Notes

- [P] tasks = different files, no dependencies
- [US] label maps to user stories from spec.md
- TDD: write test, confirm red, implement, confirm green
- Both WPs touch independent files — fully parallelizable
