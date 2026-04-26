# Tasks: subagent-per-ai-rendering

**Input**: Design documents from `/specs/006-subagent-per-ai-rendering/`

**Tests**: TDD per Principle II. Each WP gets tests before implementation.

## Phase 1: Setup

- [ ] T001 Create `tests/test_subagent_rendering.py` with a sample subagent content fixture

---

## Phase 2: US-1 — Fix Codex agent directory (WP-1)

- [ ] T002 [P] [US1] Test Codex `custom_agents_dest` returns `.codex/agents/` in tests/test_subagent_rendering.py
- [ ] T003 [US1] Change Codex config `folder` from `.agents/` to `.codex/` in `src/kiss_cli/integrations/codex/__init__.py`

---

## Phase 3: US-2 — OpenCode `mode: subagent` (WP-2)

- [ ] T004 [P] [US2] Test OpenCode transform injects `mode: subagent` into frontmatter in tests/test_subagent_rendering.py
- [ ] T005 [US2] Override `transform_custom_agent_content` in `src/kiss_cli/integrations/opencode/__init__.py` to inject `mode: subagent`

---

## Phase 4: US-3 — Gemini `kind: subagent` (WP-3)

- [ ] T006 [P] [US3] Test Gemini transform injects `kind: subagent` into frontmatter in tests/test_subagent_rendering.py
- [ ] T007 [US3] Override `transform_custom_agent_content` in `src/kiss_cli/integrations/gemini/__init__.py` to inject `kind: subagent`

---

## Phase 5: US-4 — Windsurf workflow adaptation (WP-4)

- [ ] T008 [P] [US4] Test Windsurf `custom_agents_dest` returns `.windsurf/workflows/` in tests/test_subagent_rendering.py
- [ ] T009 [P] [US4] Test Windsurf transform strips frontmatter and returns plain Markdown in tests/test_subagent_rendering.py
- [ ] T010 [US4] Set Windsurf `agents_subdir` to `workflows` in `src/kiss_cli/integrations/windsurf/__init__.py`
- [ ] T011 [US4] Override `transform_custom_agent_content` in Windsurf to strip frontmatter in `src/kiss_cli/integrations/windsurf/__init__.py`

---

## Phase 6: US-5 — Codex frontmatter adaptation (WP-5)

- [ ] T012 [P] [US5] Test Codex transform adds `developer_instructions` from body in tests/test_subagent_rendering.py
- [ ] T013 [US5] Override `transform_custom_agent_content` in `src/kiss_cli/integrations/codex/__init__.py`

---

## Phase 7: US-6 — Strip unsupported fields (WP-6)

- [ ] T014 [P] [US6] Test Cursor transform strips `color` and `tools` from frontmatter in tests/test_subagent_rendering.py
- [ ] T015 [P] [US6] Test base class transform strips `color` field by default in tests/test_subagent_rendering.py
- [ ] T016 [US6] Override `transform_custom_agent_content` in Cursor to strip `color` and `tools` in `src/kiss_cli/integrations/cursor_agent/__init__.py`
- [ ] T017 [US6] Update base `transform_custom_agent_content` to strip `color` field in `src/kiss_cli/integrations/base.py`

---

## Phase 8: Polish

- [ ] T018 Run full test suite — verify zero regressions
- [ ] T019 [P] Update `docs/specs/requirement-debts.md` — resolve RDEBT-025/026/027/028/035
- [ ] T020 [P] Update existing integration tests that check directory paths for Codex

---

## Dependencies

All WPs are independent (different integration files). Phase 8 depends on all.
