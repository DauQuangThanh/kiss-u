# Tasks: skill-renames

**Input**: Design documents from `/specs/005-skill-renames/`

## Phase 1: Rename directories + files + frontmatter (WP-1)

- [ ] T001 [P] Rename `kiss-acceptance` → `kiss-acceptance-criteria` (dir + .md + frontmatter)
- [ ] T002 [P] Rename `kiss-checklist` → `kiss-feature-checklist` (dir + .md + frontmatter)
- [ ] T003 [P] Rename `kiss-pm-planning` → `kiss-project-planning` (dir + .md + frontmatter)
- [ ] T004 [P] Rename `kiss-cicd` → `kiss-cicd-pipeline` (dir + .md + frontmatter)
- [ ] T005 [P] Rename `kiss-monitoring` → `kiss-observability-plan` (dir + .md + frontmatter)
- [ ] T006 [P] Rename `kiss-deployment` → `kiss-deployment-strategy` (dir + .md + frontmatter)
- [ ] T007 [P] Rename `kiss-infra` → `kiss-infrastructure-plan` (dir + .md + frontmatter)
- [ ] T008 [P] Rename `kiss-adr` → `kiss-adr-author` (dir + .md + frontmatter)
- [ ] T009 [P] Rename `kiss-change-register` → `kiss-change-log` (dir + .md + frontmatter)

## Phase 2: Update cross-references (WP-2)

- [ ] T010 Grep all skill prompts for old names and update references
- [ ] T011 Update `.claude/skills/` installed skill references if any

## Phase 3: Update spec documentation (WP-3)

- [ ] T012 Update Naming Audit Appendix in `docs/specs/agent-skills-system/spec.md`
- [ ] T013 Resolve RDEBT-029 and RDEBT-031 in `docs/specs/requirement-debts.md`

## Phase 4: Polish

- [ ] T014 Run full test suite
- [ ] T015 Run markdownlint on modified files
