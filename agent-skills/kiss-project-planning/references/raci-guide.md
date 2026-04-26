# RACI matrix — guide

RACI defines roles per deliverable so no work falls through the cracks.

| Letter | Role | Definition |
|---|---|---|
| **R** | **Responsible** | Does the work |
| **A** | **Accountable** | Has final authority; **must be one person per task** |
| **C** | **Consulted** | Provides input; usually subject-matter experts |
| **I** | **Informed** | Kept in the loop; does not make decisions |

## Worked example — "Architecture review"

- **Responsible:** Tech Lead (does the review)
- **Accountable:** PM (final decision to approve/reject)
- **Consulted:** Security team, QA lead (give feedback)
- **Informed:** Dev team, Stakeholders (told of outcome)

## Common mistakes

- **Two Accountables on the same row** — violates RACI; pick one.
- **Nobody Accountable** — the task will stall at decision time.
- **Everyone Responsible** — no-one is actually on the hook.
- **Consulted too many people** — decision velocity drops; only
  name people whose input materially changes the outcome.

## Guidance for AI-drafted plans

The AI can **draft** the RACI matrix from the project plan and
stakeholder list, but the assignments are decisions only humans
can make. Record proposed assignments and flag them for user
confirmation.
