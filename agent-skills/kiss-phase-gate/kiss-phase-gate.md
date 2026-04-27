---
name: kiss-phase-gate
description: >-
  Authors a Waterfall phase-exit checklist and sign-off page for a
  named gate (Requirements, Architecture / CDR, Test Readiness / TRR,
  Operational Readiness / ORR, or Go-Live). Verifies entry and exit
  criteria against upstream artefacts, lists all required deliverables
  with their status, and produces a dated gate record the project
  manager uses to decide whether the project may proceed to the next
  phase. Use when a Waterfall project reaches a phase boundary, when
  a customer or PMO requires formal gate sign-off, or when conducting
  a Milestone Review.
license: MIT
compatibility: Designed for Claude Code and agentskills.io-compatible agents.
metadata:
  author: Dau Quang Thanh
  version: '1.0'
---

## User Input

```text
$ARGUMENTS
```

Consider the user input before proceeding (if not empty). If the
argument names a gate (e.g. `requirements`, `architecture`, `ttr`,
`orr`, `go-live`), pre-select that gate type.

## Audience and tone (interactive mode)

When `KISS_AGENT_MODE=interactive` (the default), assume the user
has **limited technical background and limited domain knowledge**.
Run this skill as a guided questionnaire:

- **One question at a time.** No walls of questions.
- **Yes / no first.** Phrase so `yes`, `no`, `not sure`, or `skip`
  is a valid answer.
- **Translate jargon, don't strip it.** Explain CDR, TRR, ORR,
  entry/exit criteria on first use.
- **Choices, not blank fields.** Offer lettered options (A/B/C/D).
  Always include "Not sure — sensible default".
- **Always recommend.** State which option you would pick and why.
- **Show, don't ask.** Pre-fill from upstream artefacts; ask for
  yes / no confirmation.
- **`not sure` / `skip` triggers a sensible default**, marked
  "(default applied)" and a GATEDEBT entry.

When `KISS_AGENT_MODE=auto`, skip the questionnaire and log
decisions.

## Gate types

| Short name | Full name | Typical preceding phase |
|---|---|---|
| `requirements` | System Requirements Review (SRR) | Requirements |
| `architecture` | Critical Design Review (CDR) | Architecture & Design |
| `ttr` | Test Readiness Review (TRR) | Implementation |
| `orr` | Operational Readiness Review (ORR) | Verification / UAT |
| `go-live` | Go/No-Go Review | Deployment |

## Inputs

- `.kiss/context.yml`
- `{context.paths.docs}/architecture/srs.md` — requirements baseline
- `{context.paths.docs}/architecture/srs.extract` — SRS_REVISION
- `{context.paths.docs}/analysis/traceability-matrix.extract` —
  COVERAGE_PCT, UNCOVERED_REQS (for requirements and ttr gates)
- `{context.paths.docs}/project/project-plan.md` — WBS, milestones,
  risk register reference
- `{context.paths.docs}/project/risk-register.md` — open high risks
- `{context.paths.docs}/testing/<feature>/strategy.md` (ttr gate)
- `{context.paths.docs}/testing/<feature>/test-execution.md` (orr / go-live)
- `{context.paths.docs}/operations/deployment-strategy.md` (orr / go-live)

## Outputs

- `{context.paths.docs}/project/gates/GATE-<type>-<YYYY-MM-DD>.md` —
  the gate record (primary artefact)
- `{context.paths.docs}/project/gates/GATE-<type>-<YYYY-MM-DD>.extract` —
  companion KEY=VALUE ledger
  (GATE_TYPE, GATE_OUTCOME, OPEN_BLOCKERS, GATE_DATE)
- `{context.paths.docs}/project/gates/gate-debts.md` — items that
  must be resolved before gate can be passed (GATEDEBT-NN: …)

## Context Update

Does not mutate `.kiss/context.yml`.

## Handoffs

- `kiss-baseline` should be run immediately after a Requirements
  (SRR) or Architecture (CDR) gate passes, to freeze the baseline.
- `kiss-status-report` reads gate records to report milestone
  achievement.
- `kiss-risk-register` is read to populate the open-risk section.

## AI authoring scope

**Does:**

- Populate entry/exit criteria for the selected gate type from
  industry-standard checklists (IEEE 15288, ISO/IEC 12207,
  PMBOK 7th edition, BABOK v3).
- Check each criterion against available upstream artefacts and
  mark it as Pass / Fail / Unknown / N/A.
- Produce a gate record the PM and stakeholders sign.
- Flag any blocker as a GATEDEBT entry.

**Does not:**

- Pass or fail the gate on the user's behalf.
- Override a "Fail" criterion without explicit user instruction.
- Modify upstream artefacts.

## Outline

1. **Determine gate type** — from user input or prompt a choice:
   A) Requirements review, B) Architecture/CDR, C) Test readiness
   (TRR), D) Operational readiness (ORR), E) Go-Live.

2. **Load upstream artefacts** relevant to the selected gate type
   (see Inputs). Note which are present and which are missing.

3. **Interactive questionnaire** (interactive mode only):
   a. Confirm gate type and date.
   b. List any deliverables the AI could not locate — ask whether
      they exist elsewhere or should be marked "Not delivered".
   c. For each open high-risk item, ask whether it is accepted,
      mitigated, or a blocker.

4. **Evaluate criteria** — for each criterion in the gate checklist
   template, determine status by inspecting the relevant artefact:
   - **Pass** — criterion is fully met by available evidence.
   - **Fail** — criterion is not met; raise GATEDEBT.
   - **Unknown** — artefact not found; raise GATEDEBT.
   - **N/A** — criterion does not apply to this project.

5. **Draft gate record** — fill `templates/gate-template.md` with:
   - Cover: gate type, date, project, phase transition statement.
   - Deliverables checklist with status.
   - Entry/exit criteria table with Pass / Fail / N/A.
   - Open risks with severity and owner.
   - Blockers list (GATEDEBT entries that prevent proceeding).
   - Conditional approvals / waivers section.
   - Sign-off table (PM, Tech Lead, QA Lead, Customer/Sponsor).

6. **Write outputs** — write gate record, `.extract`, and append
   to `gate-debts.md`.

7. **Recommendation** — state in one line whether the gate evidence
   supports a Pass, Conditional Pass, or Fail outcome, and list the
   top 3 actions needed.

## Usage

> `<SKILL_DIR>` = the integration's skills root.

```bash
GATE_TYPE="requirements" \
GATE_DATE="2026-05-01" \
  bash <SKILL_DIR>/kiss-phase-gate/scripts/bash/run-gate.sh --auto
```

### Answer keys

| Key | Meaning | Default |
|---|---|---|
| `GATE_TYPE` | `requirements` / `architecture` / `ttr` / `orr` / `go-live` | *(required)* |
| `GATE_DATE` | ISO date of the review | today |
| `GATE_COVERAGE_THRESHOLD` | Minimum RTM coverage % to pass ttr/orr | `80` |
