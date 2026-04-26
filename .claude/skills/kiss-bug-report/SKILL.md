---
name: "kiss-bug-report"
description: "Author a structured bug report file per bug at docs/bugs/BUG-NNN-<slug>.md. Captures repro, expected vs actual, severity, affected version, and traceability to the failed test case or user story."
compatibility: "Requires kiss project structure with .kiss/ directory"
metadata:
  author: "github-kiss"
  source: "agent-skills/kiss-bug-report/kiss-bug-report.md"
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
- `{context.paths.docs}/testing/<feature>/execution.md` (to
  link a failed run)
- `{context.paths.specs}/<feature>/spec.md` (user-story traceability)

## Outputs

- `{context.paths.docs}/bugs/BUG-NNN-<slug>.md` (auto-numbered)

## Context Update

Does not mutate `.kiss/context.yml`.

## Handoffs

- `kiss-bug-triage` consumes bug files to produce a triage list.
- `kiss-change-register` links the fix commit.
- `kiss-regression-tests` generates a regression test per fixed bug.

## AI authoring scope

**Does:** scaffold a bug report with the required fields, propose
a severity + priority from the symptom description, link to
upstream artefacts.

**Does not:** decide severity / priority the user hasn't confirmed,
assign the bug, or close it.

## Usage

> `<SKILL_DIR>` = the integration's skills root (e.g. `.claude/skills/`
> for Claude Code, `.agents/skills/` for Antigravity / Codex,
> `.cursor/skills/` for Cursor, `.windsurf/workflows/` for Windsurf).
> Scripts live at `<SKILL_DIR>/<skill-name>/scripts/…`.

```bash
BUG_TITLE="Login 500 on empty password" \
BUG_STEPS="1. open /login\n2. submit with empty password field" \
BUG_EXPECTED="400 validation error" \
BUG_ACTUAL="500 + stack trace" \
BUG_SEVERITY="high" BUG_PRIORITY="high" \
BUG_FAILED_TC="TC-04" BUG_AFFECTED_VERSION="1.3.2" \
  bash <SKILL_DIR>/kiss-bug-report/scripts/bash/add-bug.sh --auto
```

### Answer keys

| Key | Meaning | Default |
|---|---|---|
| `BUG_TITLE` | one-line summary | *(required)* |
| `BUG_STEPS` | reproduction steps (newline-separated) | *(required)* |
| `BUG_EXPECTED` | what should happen | *(required)* |
| `BUG_ACTUAL` | what actually happens | *(required)* |
| `BUG_SEVERITY` | critical / high / medium / low | `medium` |
| `BUG_PRIORITY` | critical / high / medium / low | `medium` |
| `BUG_AFFECTED_VERSION` | version / commit / env | empty |
| `BUG_FAILED_TC` | TC id from execution ledger | empty |
| `BUG_USER_STORY` | US id from spec | empty |
