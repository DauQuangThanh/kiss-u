---
name: "kiss-project-planning"
description: "Drafts and maintains a project plan: scope statement, work breakdown structure (WBS), milestones, dependencies, critical path, resource allocation, and Definition of Done. Supports Agile/Scrum, Kanban, Waterfall, and Hybrid methodologies. Also drafts the companion communication plan. Does not schedule meetings or commit a team. Use when starting a project, creating a project plan, defining milestones, or managing WBS and delivery schedule."
compatibility: "Requires kiss project structure with .kiss/ directory"
metadata:
  author: "github-kiss"
  source: "agent-skills/kiss-project-planning/kiss-project-planning.md"
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
- **No jargon.** Translate to everyday words: "Who decides?" not
  "Who's the Accountable in the RACI?"; "list of tasks" not "WBS";
  "what 'finished' means" not "Definition of Done"; "in batches /
  in flow / in phases" instead of "Agile / Kanban / Waterfall"
  (then translate the chosen plain answer back to the methodology
  internally).
- **Choices, not blank fields.** When yes/no isn't enough, offer
  2-4 lettered options (A/B/C/D) with one-line everyday
  descriptions. Always include "Not sure — pick a sensible default".
- **Always recommend.** State the option you would pick and why in
  one sentence so the user can reply "yes" / "ok" to accept.
- **`not sure` / `skip` triggers a sensible default** entry,
  marked "(default applied — confirm later)" in `project-plan.md`,
  and a `PMDEBT-` entry in `pm-debts.md`.

When `KISS_AGENT_MODE=auto` (or `--auto`), skip the questionnaire
entirely: apply sensible defaults from upstream artefacts and log
decisions to the project-manager agent's decision log.

## Inputs

- `.kiss/context.yml` → `paths.docs`, `current.feature`, `current.branch`
- Upstream artefacts the skill reads when present:
  - `{context.paths.specs}/**/spec.md` — feature specs from the
    business-analyst
  - `{context.paths.docs}/architecture/*.md` — architect outputs
    for technology stack, constraints, NFRs
  - `{context.paths.docs}/product/backlog.md` and `roadmap.md` —
    product-owner outputs (feature list + delivery windows)

## Outputs

- `{context.paths.docs}/project/project-plan.md` — primary planning
  artefact. Contains scope, WBS, milestones, schedule, dependencies,
  resource table, and Definition of Done.
- `{context.paths.docs}/project/project-plan.extract` — companion
  KEY=VALUE ledger (project_name, methodology, start_date,
  target_go_live, …) consumed by downstream skills.
- `{context.paths.docs}/project/communication-plan.md` — optional
  companion artefact. Lists stakeholder groups, channels, cadence,
  RACI matrix, and escalation path. Written only when the user
  confirms the project needs a formal comms plan.

## Context Update

This skill does not mutate `.kiss/context.yml`. It reads
`current.feature` but never writes to it.

## Handoffs

- `kiss-risk-register` reads the methodology, milestones, and
  critical-path entries from `project-plan.extract` to suggest
  relevant risk categories.
- `kiss-status-report` reads the milestones + DoD to compute RAG
  status against plan.
- `kiss-change-control` reads the scope statement to judge whether
  an incoming change-request exceeds it.

## AI authoring scope

This skill is an AI authoring aid. It:

- Drafts the project plan and communication plan from facts the
  user supplies (scope, milestones, team structure, methodology).
- Asks the human user at the keyboard for missing information, one
  question at a time.
- Reads existing specs/architecture/product outputs when present
  and incorporates them without re-asking.
- Honours `{context.preferences.confirm_before_write}`.
- Logs a `PMDEBT-NN` entry to
  `{context.paths.docs}/project/pm-debts.md` whenever a required
  input is missing, the `--auto` default kicked in, or a decision
  cannot be made without a human.

It does **not**:

- Schedule meetings, invite attendees, or send notifications.
- Negotiate with vendors, contract resources, or secure budget.
- Commit any team member to a task or deadline.
- Approve a milestone, release, or go-live.
- Communicate with stakeholders on the user's behalf.

## Usage

> `<SKILL_DIR>` = the integration's skills root (e.g. `.claude/skills/`
> for Claude Code, `.agents/skills/` for Antigravity / Codex,
> `.cursor/skills/` for Cursor, `.windsurf/workflows/` for Windsurf).
> Scripts live at `<SKILL_DIR>/<skill-name>/scripts/…`.

```bash
# Interactive — the AI asks you questions and writes the plan.
bash <SKILL_DIR>/kiss-project-planning/scripts/bash/draft-plan.sh

# Non-interactive — provide an answers file or env vars.
bash <SKILL_DIR>/kiss-project-planning/scripts/bash/draft-plan.sh --auto --answers ./pm-answers.env

# Dry-run — compute the output path + preview, do not write.
bash <SKILL_DIR>/kiss-project-planning/scripts/bash/draft-plan.sh --dry-run
```

PowerShell parity: `pwsh <SKILL_DIR>/kiss-project-planning/scripts/powershell/draft-plan.ps1 [-Auto] [-Answers FILE] [-DryRun]`.

### Answer keys (env or answers file)

| Key | Meaning | Default |
|---|---|---|
| `PM_PROJECT_NAME` | Human-readable project name | derived from `current.feature` |
| `PM_METHODOLOGY` | `agile`, `scrum`, `kanban`, `waterfall`, `hybrid` | `scrum` |
| `PM_START_DATE` | ISO date `YYYY-MM-DD` | today |
| `PM_TARGET_GO_LIVE` | ISO date `YYYY-MM-DD` | empty (→ debt) |
| `PM_TEAM_SIZE` | Integer | empty (→ debt) |
| `PM_SPONSOR` | Project sponsor name | empty (→ debt) |
| `PM_INCLUDE_COMMS_PLAN` | `true`/`false` | `false` |

## Interactive flow (when scripts can't run)

If the shell scripts are unavailable, ask the user the following in
order, writing answers into `docs/project/project-plan.md` by hand
using `templates/project-plan-template.md`:

1. Confirm the project name (derived from `current.feature` or ask).
2. Pick the methodology (`1. agile/scrum`, `2. kanban`,
   `3. waterfall`, `4. hybrid`).
3. Top-level WBS items — list 3–7 phases (e.g. planning, design,
   dev, test, deploy).
4. Key milestones with target dates + acceptance criteria.
5. Critical path and dependencies between phases.
6. Resource allocation (dedicated team / shared / mixed / TBD).
7. Definition of Done at the project level.
8. Does the project need a formal communication plan? If yes,
   ask the user to list stakeholder groups, preferred channels,
   meeting cadence, and escalation tiers — write the answers into
   `docs/project/communication-plan.md` using
   `templates/communication-plan-template.md`.

Methodology-specific emphasis (see
`references/methodology-adaptations.md`):

- **Agile/Scrum** — frame milestones as sprint goals; highlight
  velocity and burndown; communicate via standup + sprint review.
- **Kanban** — drop fixed milestones in favour of WIP limits + flow.
- **Waterfall** — milestones are phase gates with formal sign-off.
- **Hybrid** — mark which parts are fixed vs. flexible.

## Debt register

Every unresolved input or `--auto` default is logged as:

```text
PMDEBT-NN: <short description>
```

…into `{context.paths.docs}/project/pm-debts.md`. Include:

- Area (Scope / Schedule / Resource / Budget / Quality / Comms)
- Impact (what cannot be decided without this)
- Owner (who should answer — usually the user)
- Priority (🔴 Blocking / 🟡 Important / 🟢 Can wait)

## References

- `references/pmbok-areas.md` — PMBOK knowledge areas + key
  deliverables.
- `references/methodology-adaptations.md` — how planning language
  shifts by methodology.
- `references/raci-guide.md` — Responsible / Accountable /
  Consulted / Informed definitions and a worked example.
- `references/waterfall-phase-gates.md` — formal gate definitions.
- `references/pm-glossary.md` — common PM vocabulary.
