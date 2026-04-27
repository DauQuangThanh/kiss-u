---
name: "kiss-handover"
description: "Drafts the operations and support hand-over package for a feature or release. Assembles the runbook index, on-call rota seed, support escalation matrix, known limitations, training-material checklist, warranty / hypercare period definition, and knowledge-transfer session plan. Produces a self-contained package the development team hands to the operations / support team at go-live. Use at the end of a Waterfall project after the Go/No-Go gate passes, when transitioning from project to BAU (business-as-usual) support, or when a contractual hand-over document is required."
compatibility: "Requires kiss project structure with .kiss/ directory"
metadata:
  author: "github-kiss"
  source: "agent-skills/kiss-handover/kiss-handover.md"
---


## User Input

```text
$ARGUMENTS
```

Consider the user input before proceeding (if not empty).

## Audience and tone (interactive mode)

When `KISS_AGENT_MODE=interactive` (the default), assume the user
has **limited technical background and limited domain knowledge**.
Run this skill as a guided questionnaire:

- **One question at a time.** No walls of questions.
- **Yes / no first.** Phrase so `yes`, `no`, `not sure`, or `skip`
  is a valid answer.
- **Translate jargon, don't strip it.** Explain runbook, hypercare,
  SLA, escalation matrix, BAU on first use.
- **Choices, not blank fields.** Offer lettered options (A/B/C/D).
  Always include "Not sure — sensible default".
- **Always recommend.** State which option you would pick and why.
- **Show, don't ask.** Pre-fill from deployment strategy, ADRs,
  observability plan when available.
- **`not sure` / `skip` triggers a sensible default**, marked
  "(default applied)" and an HOVRDEBT entry.

When `KISS_AGENT_MODE=auto`, skip the questionnaire and log
decisions.

## Inputs

- `.kiss/context.yml`
- `{context.paths.docs}/operations/deployment-strategy.md` —
  runbook reference, rollback procedures
- `{context.paths.docs}/operations/observability-plan.md` —
  log / metric / alert links
- `{context.paths.docs}/architecture/*.md` — tech stack,
  dependencies, ADRs
- `{context.paths.docs}/project/risk-register.md` — residual risks
  carried into BAU
- `{context.paths.docs}/testing/<feature>/uat-sign-off.md` —
  confirmed acceptance state

## Outputs

- `{context.paths.docs}/operations/handover/handover-package.md` —
  the master hand-over document (primary artefact)
- `{context.paths.docs}/operations/handover/runbook-index.md` —
  catalogue of all runbooks with location, owner, and last-tested date
- `{context.paths.docs}/operations/handover/support-escalation.md` —
  tiered escalation matrix (L1 → L2 → L3 → vendor)
- `{context.paths.docs}/operations/handover/training-checklist.md` —
  knowledge-transfer topics and completion tracking
- `{context.paths.docs}/operations/handover/handover-package.extract` —
  companion KEY=VALUE ledger
  (HANDOVER_DATE, WARRANTY_END, ONCALL_ROTA_OWNER, RUNBOOK_COUNT)
- `{context.paths.docs}/operations/handover/handover-debts.md` —
  open items (HOVRDEBT-NN: …)

## Context Update

Does not mutate `.kiss/context.yml`.

## Handoffs

- `kiss-phase-gate` (go-live gate) checks whether
  `handover-package.md` is complete before recommending Go.
- `kiss-observability-plan` is read to populate alert links and
  SLI/SLO references in the runbook index.
- `kiss-deployment-strategy` is read to populate rollback procedures.
- `kiss-status-report` references the handover-package after go-live
  in the warranty / hypercare status section.

## AI authoring scope

**Does:**

- Aggregate artefacts from upstream skills into a coherent hand-over
  document.
- Draft role-based responsibilities for L1/L2/L3 support tiers.
- Define warranty / hypercare period with developer-on-call
  obligations.
- Produce a knowledge-transfer session plan.
- List known limitations and deferred items as HOVRDEBT entries.

**Does not:**

- Schedule knowledge-transfer meetings.
- Negotiate SLAs with the support team.
- Modify any upstream artefact.

## Outline

1. **Determine scope** — feature or full release? Ask if unclear.

2. **Interactive questionnaire** (interactive mode only):
   a. Receiving team: A) internal ops, B) external managed service,
      C) customer self-support, D) not yet decided.
   b. Support tiers in use: A) L1/L2/L3, B) L1/L2 only, C) no
      tiers — single support team.
   c. Warranty / hypercare period: A) 2 weeks, B) 1 month,
      C) 3 months, D) custom.
   d. On-call required: A) yes (24/7), B) business hours only,
      C) no (next-business-day).
   e. Training format: A) written documentation only, B) recorded
      walkthroughs, C) live knowledge-transfer sessions, D) mix.

3. **Build runbook index** — scan `deployment-strategy.md` and
   `observability-plan.md` for existing runbooks. List each with
   owner, location, and last-tested date placeholder.

4. **Draft escalation matrix** — one row per tier (L1 / L2 / L3 /
   Vendor), with: trigger condition, team / person, contact method,
   response SLA, and escalation path.

5. **Draft training checklist** — topics the receiving team must
   understand before BAU, grouped by priority:
   - Critical (must complete before go-live)
   - Important (complete in first 2 weeks)
   - Reference (self-study at own pace)

6. **Draft master hand-over document** —
   fill `templates/handover-package-template.md`.

7. **Write outputs** — write all four output files and the extract.

8. **Summary** — print deliverable count, warranty end date,
   open HOVRDEBT count, and suggested next action.

## Usage

> `<SKILL_DIR>` = the integration's skills root.

```bash
HANDOVER_FEATURE="payment-checkout" \
HANDOVER_RECEIVING_TEAM="internal-ops" \
HANDOVER_WARRANTY_DAYS=30 \
  bash <SKILL_DIR>/kiss-handover/scripts/bash/draft-handover.sh --auto
```

### Answer keys

| Key | Meaning | Default |
|---|---|---|
| `HANDOVER_FEATURE` | Feature / release slug | current.feature from context |
| `HANDOVER_RECEIVING_TEAM` | `internal-ops` / `external-msp` / `customer` | `internal-ops` |
| `HANDOVER_WARRANTY_DAYS` | Hypercare / warranty days | `30` |
| `HANDOVER_ONCALL` | `247` / `business-hours` / `nbd` | `business-hours` |
