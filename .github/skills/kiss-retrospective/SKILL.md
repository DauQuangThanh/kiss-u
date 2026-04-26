---
name: "kiss-retrospective"
description: "Synthesises provided retrospective notes (or a pasted What-went-well / What-didn't / Try-next transcript) into structured action items with owners and target sprints. Does NOT facilitate the retro — the team holds it and provides the notes. Use when processing sprint retrospective notes, capturing action items from a retrospective, or converting retro output into a tracked list."
compatibility: "Requires kiss project structure with .kiss/ directory"
metadata:
  author: "github-kiss"
  source: "agent-skills/kiss-retrospective/kiss-retrospective.md"
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
- **No jargon.** Translate to everyday words: "What worked / what
  didn't / what should we try next time?" beats every formal retro
  vocabulary. Avoid "4Ls / Sailboat / SAFe metrics" without
  explanation; describe the format in plain words and let the user
  pick.
- **Accept paste-in.** Ask the user to paste the team's notes; you
  group similar points and propose action items. Don't paraphrase
  the team's wording — keep it.
- **Choices, not blank fields.** When yes/no isn't enough, offer
  2-4 lettered options (A/B/C/D) with one-line everyday
  descriptions. Always include "Not sure — pick a sensible default".
- **Always recommend.** State the option you would pick and why in
  one sentence so the user can reply "yes" / "ok" to accept. For
  action-item owners, default to "blank" unless the notes name
  someone — never assign a person without their consent.
- **`not sure` / `skip` triggers a sensible default**: leave owner
  blank, leave target sprint blank, mark
  "(default applied — confirm later)", and log a `SMDEBT-` entry in
  `agile-debts.md`.

When `KISS_AGENT_MODE=auto` (or `--auto`), skip the questionnaire
entirely: synthesise pasted notes into themes + action items
without asking, leave owners blank where unnamed, and log decisions
to the scrum-master agent's decision log.

## Inputs

- `.kiss/context.yml` → `paths.docs`
- `{context.paths.docs}/agile/sprint-NN-plan.md` — sprint being
  retrospected
- `{context.paths.docs}/agile/standups/*.md` — the sprint's daily
  logs (patterns, recurring blockers)
- Free-text retro notes the user pastes (or a notes file)

## Outputs

- `{context.paths.docs}/agile/retro-sprint-NN.md`
- `{context.paths.docs}/agile/action-items.md` (append-only;
  action items carry across retros)

## Context Update

Does not mutate `.kiss/context.yml`.

## Handoffs

- `kiss-sprint-planning` for the next sprint reads action-items.md
  and optionally includes items targeting the next sprint.
- `kiss-status-report` references open action items when reporting
  team health.

## AI authoring scope

**Does:**

- Accept the team's retro notes (What went well / What didn't /
  What to try) from stdin, `--notes FILE`, or inline env var.
- Group similar points; propose action items with owner + target
  sprint left blank for the user to fill.
- Scan standup files for recurring blockers and propose those as
  retro fodder if the notes didn't mention them.

**Does not:**

- Facilitate the retrospective; invite team members; ask them
  questions.
- Assign action items to individuals the user hasn't named.
- Decide what the team "should" have done.

## Usage

> `<SKILL_DIR>` = the integration's skills root (e.g. `.claude/skills/`
> for Claude Code, `.agents/skills/` for Antigravity / Codex,
> `.cursor/skills/` for Cursor, `.windsurf/workflows/` for Windsurf).
> Scripts live at `<SKILL_DIR>/<skill-name>/scripts/…`.

```bash
cat notes.txt | bash <SKILL_DIR>/kiss-retrospective/scripts/bash/synthesize-retro.sh --auto
# or
RETRO_SPRINT=7 bash <SKILL_DIR>/kiss-retrospective/scripts/bash/synthesize-retro.sh --notes ./retro-7.txt --auto
```

### Answer keys

| Key | Meaning | Default |
|---|---|---|
| `RETRO_SPRINT` | Sprint number | latest sprint with a plan |
| `RETRO_NOTES` | Inline notes | *(one of stdin, --notes, this)* |
| `RETRO_FORMAT` | `wwwdt` (Well/Wonder/Different/Trends) or `safe` (Safe/Appreciative/Fix/Experiment) | `wwwdt` |

## References

- `references/retro-formats.md` — common retrospective formats and
  when to pick each.
