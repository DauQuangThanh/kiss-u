---
name: "kiss-standup"
description: "Logs daily standup notes from content the user pastes in. Extracts blockers into a tracked impediments list. Does NOT facilitate the standup — the team runs the meeting and tells the AI what happened. Use when recording daily standup notes, tracking impediments, or logging what each team member did yesterday / today / blocked on."
compatibility: "Requires kiss project structure with .kiss/ directory"
metadata:
  author: "github-kiss"
  source: "agent-skills/kiss-standup/kiss-standup.md"
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
- **No jargon.** Translate to everyday words: "What did each person
  finish yesterday, plan today, and what's stopping them?" instead
  of "Yesterday / Today / Blockers". Avoid "impediment", "stand-up
  cadence", "scrum-of-scrums" — say "blocker", "daily quick chat".
- **Accept paste-in.** The simplest path: ask the user to paste raw
  notes; you handle the structure. Confirm with: "Paste your raw
  notes (or describe what each person said) and I'll structure it."
- **Choices, not blank fields.** When yes/no isn't enough, offer
  2-4 lettered options (A/B/C/D) with one-line everyday
  descriptions. Always include "Not sure — pick a sensible default".
- **Always recommend.** State the option you would pick and why in
  one sentence. Default to "(no update)" for any name in the notes
  without an update next to it; never invent updates.
- **`not sure` / `skip` triggers a sensible default**: omit the
  field with a "(default applied — confirm later)" marker, and log
  a `SMDEBT-` entry in `agile-debts.md`.

When `KISS_AGENT_MODE=auto` (or `--auto`), skip the questionnaire
entirely: structure pasted notes per-person without asking, write
"(no update)" where data is missing, and log decisions to the
scrum-master agent's decision log.

## Inputs

- `.kiss/context.yml` → `paths.docs`
- `{context.paths.docs}/agile/sprint-NN-plan.md` (active sprint)
- Free-text standup notes the user pastes in

## Outputs

- `{context.paths.docs}/agile/standups/YYYY-MM-DD.md`
- `{context.paths.docs}/agile/impediments.md` (append-only ledger)

## Context Update

Does not mutate `.kiss/context.yml`.

## Handoffs

- `kiss-retrospective` reads all standup files from a sprint for
  pattern analysis.
- `kiss-status-report` reads impediments.md for the blockers
  section.

## AI authoring scope

**Does:**

- Accept free-text notes from the user (who typed them at / after
  the real standup) and structure them into Yesterday / Today /
  Blockers per team member.
- Extract explicit blockers into `impediments.md` with owner +
  target resolution.
- Timestamp and archive.

**Does not:**

- Facilitate a standup, ask team members questions, or prompt
  absent attendees.
- Assign a blocker owner the user hasn't named.
- Resolve an impediment on anyone's behalf.

## Usage

> `<SKILL_DIR>` = the integration's skills root (e.g. `.claude/skills/`
> for Claude Code, `.agents/skills/` for Antigravity / Codex,
> `.cursor/skills/` for Cursor, `.windsurf/workflows/` for Windsurf).
> Scripts live at `<SKILL_DIR>/<skill-name>/scripts/…`.

```bash
# Log today's standup. User pipes notes in or points to a notes file.
echo "Alex: y=finished SSO config; t=writing tests; b=none
Priya: y=design review; t=contract update; b=waiting on legal sign-off" \
  | bash <SKILL_DIR>/kiss-standup/scripts/bash/log-standup.sh --auto

# Or pass a file:
bash <SKILL_DIR>/kiss-standup/scripts/bash/log-standup.sh --notes ./standup-2026-04-24.txt --auto
```

### Answer keys

| Key | Meaning | Default |
|---|---|---|
| `STANDUP_DATE` | `YYYY-MM-DD` | today |
| `STANDUP_SPRINT` | sprint id | auto-detect from latest plan |
| `STANDUP_NOTES` | inline notes text (alternative to stdin / --notes) | *(one of stdin, --notes, this, required)* |
