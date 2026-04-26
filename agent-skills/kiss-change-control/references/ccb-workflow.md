# Change Control Board (CCB) — workflow reference

The CCB is a human body. The AI does not convene, facilitate, or
attend it. This reference exists so the AI can describe the workflow
correctly in templates and responses.

## Typical membership

- **PM** — chairs the meeting, owns the decision log (that's this
  skill's output).
- **Product Owner** — represents business value / roadmap.
- **Tech Lead / Architect** — represents feasibility / risk.
- **QA Lead** — represents quality impact.
- **Sponsor or delegate** — for high-priority / budget-impacting CRs.

## Cadence

- **Weekly** for active projects with frequent change.
- **Per-milestone** for waterfall projects.
- **Ad-hoc** for 🔴 Critical CRs that cannot wait.

## Inputs per CR

1. Description + proposed solution.
2. Impact assessment (draft by PM or AI).
3. Risk aggravation check — does this introduce or worsen any risk?
4. Scope comparison — does this exceed the approved scope statement?

## Outputs per CR

- Decision (Approved / Rejected / On Hold).
- Decision reason (in writing).
- Implementation plan (if approved).
- Assigned owner for implementation.

## How this AI skill fits in

- **Before the CCB** — the skill drafts the CR entry + impact
  assessment, logs debts for anything missing.
- **At the CCB** — humans review the draft, decide, and tell the
  user the outcome.
- **After the CCB** — the user re-runs the skill (or edits the
  file directly) to record the decision fields. The skill writes
  the implementation plan draft when status becomes Approved.
