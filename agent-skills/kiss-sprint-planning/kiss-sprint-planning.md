---
name: kiss-sprint-planning
description: >-
  Drafts a sprint plan — sprint goal, candidate backlog items, capacity
  arithmetic, and risk flags — from the backlog + a user-provided
  velocity. Prepares the artefact; the team owns the commitment. Does
  not facilitate a planning meeting. Use when planning a sprint,
  selecting backlog items for a sprint, or calculating team capacity.
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

## Audience and tone (interactive mode)

When `KISS_AGENT_MODE=interactive` (the default), assume the user
has **no technical or Scrum background**. Run this skill as a
guided questionnaire:

- **One question at a time.** No walls of questions.
- **Yes / no first.** Phrase so `yes`, `no`, `not sure`, or `skip`
  is a valid answer.
- **No jargon.** Translate to everyday words: "How long is one
  sprint?" *(A) 1 week, B) 2 weeks, C) 3 weeks, D) 4 weeks)*;
  "How many things does the team usually finish in that time?" not
  "What's your velocity?"; "What should we deliver this sprint?"
  not "What's the sprint goal?"; avoid "WIP / capacity points /
  refinement".
- **Choices, not blank fields.** When yes/no isn't enough, offer
  2-4 lettered options (A/B/C/D) with one-line everyday
  descriptions. Always include "Not sure — pick a sensible default".
- **Always recommend.** State the option you would pick and why in
  one sentence so the user can reply "yes" / "ok" to accept. For
  velocity, use the previous sprint's number when available.
- **`not sure` / `skip` triggers a sensible default** sprint plan
  field (recommended velocity from history; sprint goal proposed
  from the top backlog item), marked "(default applied — confirm
  later)" in `sprint-NN-plan.md`, and a `SMDEBT-` entry in
  `agile-debts.md`.

When `KISS_AGENT_MODE=auto` (or `--auto`), skip the questionnaire
entirely: pull top backlog items, propose a goal, and log decisions
to the scrum-master agent's decision log.

## Inputs

- `.kiss/context.yml` → `paths.docs`
- `{context.paths.docs}/product/backlog.md` — prioritised items
- `{context.paths.docs}/product/acceptance.md` — for DoD context
- Previous sprint's retro (`docs/agile/retro-sprint-*.md`) when
  present

## Outputs

- `{context.paths.docs}/agile/sprint-NN-plan.md`
- `{context.paths.docs}/agile/sprint-NN-plan.extract`

## Context Update

Does not mutate `.kiss/context.yml`.

## Handoffs

- `kiss-standup` references the current sprint plan when logging
  daily notes.
- `kiss-retrospective` compares planned vs. delivered at end-of-sprint.

## AI authoring scope

**Does:** draft sprint goal, propose candidate backlog items that
fit a capacity estimate, flag stories without acceptance criteria,
carry over unfinished items from previous sprint.

**Does not:** commit the team to a sprint, hold a planning meeting,
assign tasks to individuals, decide sprint goal without user input.

## Usage

> `<SKILL_DIR>` = the integration's skills root (e.g. `.claude/skills/`
> for Claude Code, `.agents/skills/` for Antigravity / Codex,
> `.cursor/skills/` for Cursor, `.windsurf/workflows/` for Windsurf).
> Scripts live at `<SKILL_DIR>/<skill-name>/scripts/…`.

```bash
SP_SPRINT_NUMBER=7 SP_GOAL="Ship SSO PoC" SP_VELOCITY=24 SP_CAPACITY=26 \
  bash <SKILL_DIR>/kiss-sprint-planning/scripts/bash/draft-sprint.sh --auto
```

### Answer keys

| Key | Meaning | Default |
|---|---|---|
| `SP_SPRINT_NUMBER` | Sprint sequence number | auto-increment from existing |
| `SP_GOAL` | Sprint goal statement | *(required)* |
| `SP_VELOCITY` | Team's recent velocity (points / items) | *(required)* |
| `SP_CAPACITY` | Capacity for this sprint (factor in leave / holidays) | = velocity |
| `SP_START_DATE` | Sprint start (`YYYY-MM-DD`) | today |
| `SP_END_DATE` | Sprint end | start + 14 days |
