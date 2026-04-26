---
name: "kiss-roadmap"
description: "Draft a product roadmap grouping backlog items into release windows (Now / Next / Later or date-based). The AI proposes windows from the backlog's priority order; the user (product-owner) confirms. Does not commit a team to a delivery date."
compatibility: "Requires kiss project structure with .kiss/ directory"
metadata:
  author: "github-kiss"
  source: "agent-skills/kiss-roadmap/kiss-roadmap.md"
user-invocable: true
disable-model-invocation: false
---


## User Input

```text
$ARGUMENTS
```

## Audience and tone (interactive mode)

When `KISS_AGENT_MODE=interactive` (the default), assume the user
has **no technical or business-domain background**. Run this skill
as a guided questionnaire:

- **One question at a time.** No walls of questions.
- **Yes / no first.** Phrase so `yes`, `no`, `not sure`, or `skip`
  is a valid answer.
- **No jargon.** Translate to everyday words: "When do you want it
  available?" not "What's the release window?"; "Now / Next /
  Later" or "this month / next month / later" instead of "Q1 / Q2".
- **Choices, not blank fields.** When yes/no isn't enough, offer
  2-4 lettered options (A/B/C/D) with one-line everyday
  descriptions. Always include "Not sure — pick a sensible default".
- **Always recommend.** State the option you would pick and why in
  one sentence so the user can reply "yes" / "ok" to accept.
- **`not sure` / `skip` triggers a sensible default** roadmap
  window, marked "(default applied — confirm later)" in
  `roadmap.md`, and a `PODEBT-` entry in `product-debts.md`.

When `KISS_AGENT_MODE=auto` (or `--auto`), skip the questionnaire
entirely: group items by the backlog's priority order and log
assumptions to the product-owner agent's decision log.

## Inputs

- `.kiss/context.yml` → `paths.docs`
- `{context.paths.docs}/product/backlog.md` — prioritised items
- `{context.paths.docs}/project/project-plan.extract` — target
  go-live and methodology hint

## Outputs

- `{context.paths.docs}/product/roadmap.md`
- `{context.paths.docs}/product/roadmap.extract`

## Context Update

Does not mutate `.kiss/context.yml`.

## Handoffs

- `kiss-pm-planning` references the roadmap's release windows when
  drafting the milestones table.
- `kiss-status-report` references the next-window items when
  listing "Planned activities next period".

## AI authoring scope

**Does:** group backlog items into Now/Next/Later (or date windows
the user specifies), draft rationale per window, propose a capacity
sanity check from team size + t-shirt totals.

**Does not:** commit delivery dates, promise features to external
stakeholders, override the product-owner's priority calls.

## Usage

> `<SKILL_DIR>` = the integration's skills root (e.g. `.claude/skills/`
> for Claude Code, `.agents/skills/` for Antigravity / Codex,
> `.cursor/skills/` for Cursor, `.windsurf/workflows/` for Windsurf).
> Scripts live at `<SKILL_DIR>/<skill-name>/scripts/…`.

```bash
bash <SKILL_DIR>/kiss-roadmap/scripts/bash/draft-roadmap.sh --auto
```

### Answer keys

| Key | Meaning | Default |
|---|---|---|
| `RM_WINDOW_STYLE` | `nnl` (Now/Next/Later) or `date` | `nnl` |
| `RM_NOW_WEEKS` | weeks in the "Now" window when date-style | `4` |
| `RM_NEXT_WEEKS` | weeks in the "Next" window | `12` |
