---
name: "kiss-status-report"
description: "Drafts a project status report (RAG status, accomplishments, next steps, budget variance, open blockers, and escalated risks) from facts the user supplies and upstream artefacts. Produces a dated report file the user can share with stakeholders; does not send it. Use when preparing a project status update, creating a weekly or monthly report, or communicating project health to stakeholders."
compatibility: "Requires kiss project structure with .kiss/ directory"
metadata:
  author: "github-kiss"
  source: "agent-skills/kiss-status-report/kiss-status-report.md"
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
- **No jargon.** Translate to everyday words: ask "How's it going
  overall?" *(A) on track (green), B) some bumps but fixable
  (amber / yellow), C) in trouble (red), D) not sure)* instead of
  "What's the RAG status?". Use "what got done" / "what's next" /
  "what's stuck" instead of "accomplishments / planned work /
  blockers". Don't ask about "budget variance" without context —
  say "Did anything cost more or less than expected?".
- **Choices, not blank fields.** When yes/no isn't enough, offer
  2-4 lettered options (A/B/C/D) with one-line everyday
  descriptions. Always include "Not sure — pick a sensible default".
- **Always recommend.** State the option you would pick and why in
  one sentence so the user can reply "yes" / "ok" to accept. For
  the overall rating, propose a colour based on the artefacts (open
  blockers → amber; missed milestone → red) and ask the user to
  confirm.
- **`not sure` / `skip` triggers a sensible default** in the report,
  marked "(default applied — confirm later)" in
  `status-YYYY-MM-DD.md`, and a `PMDEBT-` entry in `pm-debts.md`.

When `KISS_AGENT_MODE=auto` (or `--auto`), skip the questionnaire
entirely: synthesise the report from upstream artefacts (project
plan, risk register, change log) and log decisions to the
project-manager agent's decision log.

## Inputs

- `.kiss/context.yml` → `paths.docs`, `current.feature`
- `{context.paths.docs}/project/project-plan.extract` — methodology,
  milestones, target go-live
- `{context.paths.docs}/project/risk-register.extract` — Red / Amber
  counts for escalation section
- `{context.paths.docs}/project/change-log.md` — recent approved /
  pending change requests
- `{context.paths.docs}/bugs/BUG-*.md` — open critical bugs

## Outputs

- `{context.paths.docs}/project/status-YYYY-MM-DD.md` — the report,
  dated by reporting date (one file per reporting period).
- Matching `.extract` companion with the top-level KPIs.

## Context Update

Does not mutate `.kiss/context.yml`.

## Handoffs

- Intended audience: project sponsor, steering committee, delivery
  leads. The file is a draft the user reviews and sends.
- `kiss-retrospective` may reference status reports when looking
  back at a sprint/period.

## AI authoring scope

This skill is an AI authoring aid. It:

- Drafts the status report from facts the user types in plus what
  the upstream `.extract` files already expose.
- Computes a tentative RAG status against plan from provided data
  (schedule variance, open Red risks, budget variance).
- Presents the RAG status as a **proposal** the user must confirm.
- Writes one dated file per reporting period; never overwrites a
  prior period's report.

It does **not**:

- Send the report to anyone.
- Decide the actual RAG status (the AI proposes; the user calls it).
- Commit to deadlines or hand-wave variance that the user hasn't
  confirmed.

## Usage

> `<SKILL_DIR>` = the integration's skills root (e.g. `.claude/skills/`
> for Claude Code, `.agents/skills/` for Antigravity / Codex,
> `.cursor/skills/` for Cursor, `.windsurf/workflows/` for Windsurf).
> Scripts live at `<SKILL_DIR>/<skill-name>/scripts/…`.

```bash
# Interactive — the AI asks you for this period's facts.
bash <SKILL_DIR>/kiss-status-report/scripts/bash/draft-status.sh

# Non-interactive — provide an answers file.
bash <SKILL_DIR>/kiss-status-report/scripts/bash/draft-status.sh --auto --answers ./this-week.env
```

PowerShell parity: `pwsh <SKILL_DIR>/kiss-status-report/scripts/powershell/draft-status.ps1 [-Auto] [-Answers FILE] [-DryRun]`.

### Answer keys

| Key | Meaning | Default |
|---|---|---|
| `STATUS_PERIOD_START` | Start of reporting period (`YYYY-MM-DD`) | 7 days ago |
| `STATUS_PERIOD_END` | End of reporting period (`YYYY-MM-DD`) | today |
| `STATUS_REPORT_DATE` | Date on the report | today |
| `STATUS_RAG` | Proposed RAG: `green` / `amber` / `red` | auto-computed from extracts |
| `STATUS_ACCOMPLISHMENTS` | `;`-separated list of achievements | empty (→ debt) |
| `STATUS_PLANNED` | `;`-separated list of next-period items | empty (→ debt) |
| `STATUS_BLOCKERS` | `;`-separated list of blockers | `none` |
| `STATUS_BUDGET_VARIANCE` | `on-track` / `over-%` / `under-%` | `on-track` |

## RAG computation (auto mode)

When `STATUS_RAG` is not provided, the script tentatively computes:

- **Red** if any Red risk is open OR any schedule milestone has
  slipped past its target date.
- **Amber** if any Amber risk is open OR a change-request with
  `High` schedule impact is pending.
- **Green** otherwise.

This is always stamped as "(AI proposal — confirm with user)" in
the report. Humans make the call.

## Interactive flow

Ask in order:

1. Reporting period start and end dates.
2. Top 3–5 accomplishments this period (bullet list).
3. Top 3–5 planned items for the next period.
4. Budget status (on track / over / under + %).
5. Open blockers — description, impact, owner, target resolution.
6. Read `risk-register.extract`; if any Red risks, list them in the
   "Risks escalated this period" section.
7. Propose a RAG status and ask the user to confirm.

Write the report using `templates/status-report-template.md`.

## Debt register

Missing accomplishments/planned items → `PMDEBT-NN` into
`{context.paths.docs}/project/pm-debts.md`. A status report with
no accomplishments is still useful (the AI notes the gap); an
auto-computed RAG the user hasn't confirmed is a priority-🟡 debt.

## References

- `references/agile-metrics.md` — velocity, burndown, cycle time
  definitions for teams using agile/scrum.
- `references/rag-status-guide.md` — how to judge Red / Amber /
  Green consistently across periods.
- `references/status-report-best-practices.md` — what to include,
  what to cut.
