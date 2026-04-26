---
name: "kiss-change-control"
description: "Maintain a project change-request ledger. Capture incoming change requests, draft impact assessments (scope / schedule / budget / quality), record CCB decisions the user reports, and track implementation. The AI authors and maintains the ledger; it never approves, rejects, or decides a change itself."
compatibility: "Requires kiss project structure with .kiss/ directory"
metadata:
  author: "github-kiss"
  source: "agent-skills/kiss-change-control/kiss-change-control.md"
user-invocable: true
disable-model-invocation: false
---


## User Input

```text
$ARGUMENTS
```

Consider the user input before proceeding (if not empty).

## Audience and tone (interactive mode)

When `KISS_AGENT_MODE=interactive` (the default), assume the user
has **no technical or project-management background**. Run this
skill as a guided questionnaire:

- **One question at a time.** No walls of questions.
- **Yes / no first.** Phrase so `yes`, `no`, `not sure`, or `skip`
  is a valid answer.
- **No jargon.** Translate to everyday words: "What's the change
  in plain words?" not "describe the CR"; "Who asked for it?" not
  "requestor"; "Will this make the work bigger, take longer, cost
  more, or change quality?" *(yes / no per category)* instead of
  "scope / schedule / budget / quality impact"; avoid "CCB" — say
  "Who can approve this?".
- **Choices, not blank fields.** When yes/no isn't enough, offer
  2-4 lettered options (A/B/C/D) with one-line everyday
  descriptions. Always include "Not sure — pick a sensible default".
- **Always recommend.** State the option you would pick and why in
  one sentence so the user can reply "yes" / "ok" to accept. NEVER
  recommend "approved" or "rejected" — only the user can decide
  that.
- **`not sure` / `skip` triggers a sensible default** in the
  change-log entry (status defaults to "Pending"), marked
  "(default applied — confirm later)" in `change-log.md`, and a
  `PMDEBT-` entry in `pm-debts.md`.

When `KISS_AGENT_MODE=auto` (or `--auto`), skip the questionnaire
entirely: capture the change as `Pending` and log decisions to the
project-manager agent's decision log. Never auto-approve.

## Inputs

- `.kiss/context.yml` → `paths.docs`, `current.feature`
- `{context.paths.docs}/project/project-plan.extract` — scope baseline
  for impact comparison
- `{context.paths.docs}/project/risk-register.md` — known risks the
  CR might aggravate
- `{context.paths.specs}/**/spec.md` — scope definition of record

## Outputs

- `{context.paths.docs}/project/change-log.md` — the ledger. One
  entry per change-request, appended chronologically.
- `{context.paths.docs}/project/change-log.extract` — companion
  KEY=VALUE summary (counts by status).

## Context Update

Does not mutate `.kiss/context.yml`.

## Handoffs

- `kiss-pm-planning` may need re-running if an approved CR changes
  scope or critical-path milestones.
- `kiss-status-report` reads the change log to list recent CRs.
- `kiss-risk-register` reads the change log when assessing
  scope-creep risks.

## AI authoring scope

This skill is an AI authoring aid. It:

- Captures new CRs with description, requester, and proposed
  solution.
- Drafts an impact assessment across Scope / Schedule / Budget /
  Quality (H / M / L each) from project-plan and risk data.
- Records CCB decisions the user explicitly provides
  ("Approved by X on Y" / "Rejected on Z — reason: …").
- Maintains implementation notes and completion dates.

It does **not**:

- Approve or reject a change-request.
- Schedule or hold a CCB meeting.
- Update the project plan automatically on an "approved" CR —
  that's a separate, explicit run of `kiss-pm-planning`.
- Notify stakeholders of a decision.

## Usage

> `<SKILL_DIR>` = the integration's skills root (e.g. `.claude/skills/`
> for Claude Code, `.agents/skills/` for Antigravity / Codex,
> `.cursor/skills/` for Cursor, `.windsurf/workflows/` for Windsurf).
> Scripts live at `<SKILL_DIR>/<skill-name>/scripts/…`.

```bash
# Interactive — the AI asks you for this CR's fields.
bash <SKILL_DIR>/kiss-change-control/scripts/bash/add-change.sh

# Non-interactive — fields provided.
CR_DESCRIPTION="Add SSO login" \
CR_REQUESTER="Sarah (Product)" \
CR_SCOPE_IMPACT=M CR_SCHEDULE_IMPACT=M \
CR_BUDGET_IMPACT=L CR_QUALITY_IMPACT=L \
CR_PRIORITY="🟡 High" \
CR_STATUS="Pending" \
bash <SKILL_DIR>/kiss-change-control/scripts/bash/add-change.sh --auto
```

PowerShell parity: `pwsh <SKILL_DIR>/kiss-change-control/scripts/powershell/add-change.ps1 [-Auto] [-Answers FILE] [-DryRun]`.

### Answer keys

| Key | Meaning | Default |
|---|---|---|
| `CR_DESCRIPTION` | One-line description of the change | *(required)* |
| `CR_REQUESTER` | Who requested it | *(required)* |
| `CR_REASON` | Why the change is needed | empty |
| `CR_PROPOSED_SOLUTION` | What should change | empty |
| `CR_SCOPE_IMPACT` | H / M / L | `L` |
| `CR_SCHEDULE_IMPACT` | H / M / L | `L` |
| `CR_BUDGET_IMPACT` | H / M / L | `L` |
| `CR_QUALITY_IMPACT` | H / M / L | `L` |
| `CR_PRIORITY` | 🔴 Critical / 🟡 High / 🟢 Medium / 🔵 Low | `🟢 Medium` |
| `CR_STATUS` | Pending / Approved / Rejected / On Hold / Closed | `Pending` |
| `CR_APPROVED_BY` | Approver name (required when status=Approved) | empty |
| `CR_DECISION_DATE` | ISO date of approval/rejection | empty |
| `CR_DECISION_REASON` | Why approved/rejected | empty |

## Impact assessment guidance

See `references/impact-assessment-guide.md`. Quick rules:

- **H**igh impact — material change to the relevant dimension
  (new phase, >10% schedule, >10% budget, new NFR obligations).
- **M**edium — noticeable; can absorb within existing plan with
  replanning.
- **L**ow — negligible; no replanning needed.

Combine into a **priority** suggestion:

- Any H on Scope or Schedule → 🔴 Critical / 🟡 High
- H on Quality (security, compliance) → 🔴 Critical
- Otherwise → 🟢 Medium / 🔵 Low by severity of highest impact.

## Interactive flow

For each CR the user wants to log, ask in order:

1. Description (one line).
2. Requester (name + role).
3. Reason — why is this change needed?
4. Proposed solution — what will change?
5. Impact — walk through scope / schedule / budget / quality.
6. Priority (AI proposes from impact; user confirms).
7. Current status — Pending / Approved / Rejected / On Hold.
8. If Approved or Rejected: who decided, when, and the reason.
9. If Approved: what is the implementation plan (3–5 steps)?

Append entries with `CR-NN:` auto-incrementing.

## Debt register

Missing required fields or unresolved decisions → `PMDEBT-NN` in
`{context.paths.docs}/project/pm-debts.md`. A CR with `status=Approved`
but no `approved_by` is a 🟡 Important debt.

## References

- `references/impact-assessment-guide.md` — what counts as H/M/L.
- `references/ccb-workflow.md` — how a change control board is
  typically run (for reference; the AI does not run it).
