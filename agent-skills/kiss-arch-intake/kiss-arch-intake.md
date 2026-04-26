---
name: kiss-arch-intake
description: >-
  Captures architecture inputs — quality attributes ranking, hard
  constraints, team context, operational envelope, integration
  surface, deployment preferences — into a single intake artefact
  the architect works from. Use when starting system design,
  capturing requirements for an architecture, or before producing
  ADRs and C4 diagrams.
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
- `{context.paths.specs}/**/spec.md` — functional + NFR source

## Outputs

- `{context.paths.docs}/architecture/intake.md`
- `{context.paths.docs}/architecture/intake.extract`

## Context Update

Does not mutate `.kiss/context.yml`.

## Handoffs

- `kiss-tech-research` reads intake to scope candidate evaluations.
- `kiss-adr` reads constraints to frame the context of each ADR.
- `kiss-c4-diagrams` reads the integration surface for the context
  diagram.

## AI authoring scope

**Does:** ask the user structured questions, record answers,
propose sensible defaults with "(AI proposal — confirm)".

**Does not:** interview stakeholders, assume anything about budget
without the user stating it, commit the team to a stack.

## Usage

> `<SKILL_DIR>` = the integration's skills root (e.g. `.claude/skills/`
> for Claude Code, `.agents/skills/` for Antigravity / Codex,
> `.cursor/skills/` for Cursor, `.windsurf/workflows/` for Windsurf).
> Scripts live at `<SKILL_DIR>/<skill-name>/scripts/…`.

```bash
bash <SKILL_DIR>/kiss-arch-intake/scripts/bash/draft-intake.sh --auto  # uses defaults + env vars
bash <SKILL_DIR>/kiss-arch-intake/scripts/bash/draft-intake.sh         # interactive
```

### Answer keys

| Key | Default |
|---|---|
| `AI_QA_TOP5` | empty (→ debt) |
| `AI_HARD_CONSTRAINTS` | empty |
| `AI_TEAM_SIZE_BAND` | `6-15` |
| `AI_PEAK_QPS` | empty |
| `AI_SLA_TARGET` | `99.9%` |
| `AI_DEPLOY_PREF` | `no-preference` |
