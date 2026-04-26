---
name: "kiss-change-register"
description: "Maintain the change register — one row per applied bug-fix — with bug id, commit/PR, files touched, regression test, and the reviewer. Records what actually shipped; does not ship anything."
compatibility: "Requires kiss project structure with .kiss/ directory"
metadata:
  author: "github-kiss"
  source: "agent-skills/kiss-change-register/kiss-change-register.md"
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
- `{context.paths.docs}/testing/regression-index.md`

## Outputs

- `{context.paths.docs}/bugs/change-register.md`
- `{context.paths.docs}/bugs/change-register.extract`

## Context Update

Does not mutate `.kiss/context.yml`.

## Handoffs

- `kiss-regression-tests` cross-references each closed bug.
- `kiss-status-report` pulls counts for the status summary.
- `kiss-deployment` reviews the register when assembling release
  notes.

## AI authoring scope

**Does:** append one row per applied fix with bug id, commit,
files, regression-test id, reviewer; update the source bug file's
status to "Closed" once the user confirms.

**Does not:** write code, push commits, close bugs without the
user's explicit confirmation of commit + reviewer.

## Usage

> `<SKILL_DIR>` = the integration's skills root (e.g. `.claude/skills/`
> for Claude Code, `.agents/skills/` for Antigravity / Codex,
> `.cursor/skills/` for Cursor, `.windsurf/workflows/` for Windsurf).
> Scripts live at `<SKILL_DIR>/<skill-name>/scripts/…`.

```bash
CR_BUG_ID=BUG-014 CR_COMMIT=abc123 CR_PR=#512 \
CR_FILES="src/email.ts;tests/regression/bug-014.test.ts" \
CR_REGRESSION_TEST="tests/regression/bug-014.test.ts" \
CR_REVIEWER="tech-lead" \
  bash <SKILL_DIR>/kiss-change-register/scripts/bash/record-fix.sh --auto
```

### Answer keys

| Key | Meaning | Default |
|---|---|---|
| `CR_BUG_ID` | bug fixed | *(required)* |
| `CR_COMMIT` | commit SHA (short or long) | *(required)* |
| `CR_PR` | PR reference (#512) | empty |
| `CR_FILES` | `;`-separated files touched | empty |
| `CR_REGRESSION_TEST` | path to new regression test | empty (→ debt) |
| `CR_REVIEWER` | who reviewed / approved | *(required)* |
