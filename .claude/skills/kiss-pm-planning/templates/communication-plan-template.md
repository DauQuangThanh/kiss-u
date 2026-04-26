# Communication Plan: {project_name}

**Date:** {date}

## Stakeholder Groups

| Group | Members (names or roles) | Interests | Channel | Frequency |
|---|---|---|---|---|
| Executive Steering | | Budget, timeline, ROI | Monthly meeting + email | Monthly |
| Product Owner | | Scope, features, priority | Weekly sync | Weekly |
| Development Team | | Technical decisions, blockers | Standup, chat | Daily |
| QA / Testing | | Test planning, defect status | Weekly sync | Weekly |
| Operations / Support | | Runbooks, incidents | Handover meeting | Per release |

## RACI Matrix (key deliverables)

| Deliverable | Responsible | Accountable | Consulted | Informed |
|---|---|---|---|---|
| Project Plan | BA | PM | Sponsor | Team |
| Architecture Design | Tech Lead | PM | Stakeholders | Team |
| Release Candidate | Dev Lead | PM | QA | All |
| Go-Live | DevOps | PM | QA, BA | All |

See `references/raci-guide.md` for R/A/C/I definitions.

## Escalation Path

| Tier | Trigger | Notify | Escalate if unresolved by |
|---|---|---|---|
| T1 | Blocker, <2 days to fix | <name / role> | <time window> |
| T2 | Critical, <1 week to fix | <name / role> | <date> |
| T3 | Major, ≥1 week to fix | Executive Steering / CCB | Next steering meeting |

## Change-request process

1. Any team member submits a CR (form / ticket / document).
2. PM reviews and records scope / schedule / budget / quality
   impact in `change-log.md` (see `kiss-change-control`).
3. The CCB (PM, PO, Tech Lead) votes.
4. If approved: PM updates the project plan and records the
   decision in the change log.
5. If rejected: PM records the reason and closes the CR.

> **AI-only scope:** the skill authoring this document does not
> send emails, hold meetings, or notify anyone. The plan describes
> how the human team should communicate; the humans execute it.
