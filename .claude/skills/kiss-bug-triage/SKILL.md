---
name: "kiss-bug-triage"
description: "Triage open bugs into fix-now / next-sprint / defer / won't-fix buckets from severity + priority + age + business cost. Produces a dated triage list the bug-fixer / PO can act on."
compatibility: "Requires kiss project structure with .kiss/ directory"
metadata:
  author: "github-kiss"
  source: "agent-skills/kiss-bug-triage/kiss-bug-triage.md"
user-invocable: true
disable-model-invocation: false
---


## User Input

```text
$ARGUMENTS
```

## Audience and tone (interactive mode)

When `KISS_AGENT_MODE=interactive` (the default), assume the user
has **limited technical background and limited domain knowledge**
— they may know basics but lack deep expertise in this skill's
area. Run this skill as a guided questionnaire:

- **One question at a time.** No walls of questions.
- **Yes / no first.** Phrase so `yes`, `no`, `not sure`, or `skip`
  is a valid answer.
- **Translate jargon, don't strip it.** Use the technical term but
  always pair it with a plain-English gloss the first time it
  appears.
- **Choices, not blank fields.** When yes/no isn't enough, offer
  2-4 lettered options (A/B/C/D) with one-line plain-language
  descriptions of the trade-off. Always include "Not sure — pick
  a sensible default".
- **Always recommend.** State the option you would pick and why in
  one sentence so the user can reply "yes" / "ok" to accept. Pull
  defaults from upstream artefacts (spec, architecture, ADRs,
  standards) before asking blank.
- **Show, don't ask.** When upstream artefacts already imply an
  answer, propose it as a pre-filled finding and ask for a
  yes / no confirmation rather than asking the user to fill in a
  blank.
- **`not sure` / `skip` triggers a sensible default**, marked
  "(default applied — confirm later)" in the artefact, and a debt
  entry in this skill's debt file.

When `KISS_AGENT_MODE=auto` (or `--auto`), skip the questionnaire
entirely: apply sensible defaults from upstream artefacts and log
decisions to the parent agent's decision log.

## Inputs

- `.kiss/context.yml`
- `{context.paths.docs}/bugs/BUG-*.md`
- `{context.paths.docs}/bugs/change-register.md` (closed bugs)

## Outputs

- `{context.paths.docs}/bugs/triage.md` — overwrites per run
- `{context.paths.docs}/bugs/triage.extract`

## Context Update

Does not mutate `.kiss/context.yml`.

## Handoffs

- `kiss-regression-tests` produces tests for bugs marked fix-now.
- `kiss-change-register` records each fix as the bug-fixer closes.

## AI authoring scope

**Does:** read open bug files, group by bucket, propose an order,
call out stale bugs (open > 30 days).

**Does not:** close bugs, reassign, or decide won't-fix without
the user.

## Usage

> `<SKILL_DIR>` = the integration's skills root (e.g. `.claude/skills/`
> for Claude Code, `.agents/skills/` for Antigravity / Codex,
> `.cursor/skills/` for Cursor, `.windsurf/workflows/` for Windsurf).
> Scripts live at `<SKILL_DIR>/<skill-name>/scripts/…`.

```bash
bash <SKILL_DIR>/kiss-bug-triage/scripts/bash/triage.sh --auto
```

### Answer keys

| Key | Meaning | Default |
|---|---|---|
| `BT_STALE_DAYS` | threshold (days) above which a bug is "stale" | `30` |
