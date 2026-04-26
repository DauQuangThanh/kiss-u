# Feature Specification: skill-renames

**Feature Slug**: `skill-renames`
**Created**: 2026-04-26
**Status**: Draft
**Branch**: `005-skill-renames`

## Problem Statement

The agent-skills naming audit (ADR-019) identified 9 bundled
skills whose names violate naming best practices: bare nouns
without action context, jargon abbreviations, or generic terms.
This feature renames the 9 skill directories and their prompt
files to comply with the adopted rules.

## Rename Table

| # | Current name | New name | Rule |
|---|---|---|---|
| 1 | `kiss-acceptance` | `kiss-acceptance-criteria` | R5 — name the artifact |
| 2 | `kiss-checklist` | `kiss-feature-checklist` | R5 — qualify generic noun |
| 3 | `kiss-pm-planning` | `kiss-project-planning` | R5 — expand abbreviation |
| 4 | `kiss-cicd` | `kiss-cicd-pipeline` | R5 — name the artifact |
| 5 | `kiss-monitoring` | `kiss-observability-plan` | R5 — match description |
| 6 | `kiss-deployment` | `kiss-deployment-strategy` | R5 — match description |
| 7 | `kiss-infra` | `kiss-infrastructure-plan` | R5 — expand abbreviation |
| 8 | `kiss-adr` | `kiss-adr-author` | R5 — action-oriented |
| 9 | `kiss-change-register` | `kiss-change-log` | R5 — more concrete noun |

## Vendor built-in exemptions

The following skills are NOT bundled in `agent-skills/` and are
exempt from renaming: `init`, `review`, `security-review`
(Claude Code vendor built-ins), `claude-api` and `simplify`
(not in the source tree).

## Per-skill rename scope

Each rename involves:

1. Rename `agent-skills/<old>/` directory → `agent-skills/<new>/`
2. Rename `agent-skills/<new>/<old>.md` → `agent-skills/<new>/<new>.md`
3. Update `name:` field in the prompt's YAML frontmatter
4. Update any cross-references in other skill prompts or templates

## Spec documentation requirement

The complete skill name registry (all 53 `kiss-*` skills with
their canonical names post-rename) MUST be documented in
`docs/specs/agent-skills-system/spec.md` Naming Audit Appendix
so downstream tools can reference the authoritative list.

## Functional Requirements

- **FR-001**: Rename 9 skill directories per the Rename Table.
- **FR-002**: Rename the prompt `.md` file inside each directory
  to match the new directory name.
- **FR-003**: Update the `name:` YAML frontmatter field in each
  renamed prompt file.
- **FR-004**: Update the Naming Audit Appendix in
  `docs/specs/agent-skills-system/spec.md` to reflect final
  names (RENAME → DONE).
- **FR-005**: Update `docs/specs/requirement-debts.md` to resolve
  RDEBT-029 and RDEBT-031.
- **FR-006**: Update any cross-references in other skill prompts
  that reference renamed skills by old name.

## Success Criteria

- **SC-001**: All 9 renamed skill directories pass the
  agentskills.io validator (`skills-ref`).
- **SC-002**: `kiss init --integration claude` installs skills
  with the new names.
- **SC-003**: Full test suite passes with zero regressions.

## Traceability

- **Resolves**: RDEBT-029, RDEBT-031, TDEBT-029
- **ADRs**: ADR-019 (agent-skill naming and structure)
