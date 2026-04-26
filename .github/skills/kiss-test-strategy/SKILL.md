---
name: "kiss-test-strategy"
description: "Drafts the feature-scoped test strategy — scope, risk-based test priorities, levels of testing, entry/exit criteria, environments, and tooling expectations. Produces a reviewable document the test-architect and PM anchor on. Use when planning a testing approach, defining test coverage strategy, or setting entry/exit criteria for a feature."
compatibility: "Requires kiss project structure with .kiss/ directory"
metadata:
  author: "github-kiss"
  source: "agent-skills/kiss-test-strategy/kiss-test-strategy.md"
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
- `{context.paths.specs}/<feature>/spec.md`
- `{context.paths.docs}/architecture/intake.md`
- `{context.paths.docs}/project/risk-register.md`

## Outputs

- `{context.paths.docs}/testing/<feature>/strategy.md`
- `{context.paths.docs}/testing/<feature>/strategy.extract`

## Context Update

Does not mutate `.kiss/context.yml`.

## Handoffs

- `kiss-test-framework` consumes the strategy's tooling section.
- `kiss-test-cases` consumes levels + risk tiers.
- `kiss-quality-gates` consumes entry/exit criteria.

## AI authoring scope

**Does:** draft levels (unit / integration / e2e / contract /
performance / security), risk-tiered priorities, test environments
needed, entry/exit criteria.

**Does not:** choose the framework yet (that's `kiss-test-framework`),
commit the team to coverage percentages they haven't agreed.

## Usage

> `<SKILL_DIR>` = the integration's skills root (e.g. `.claude/skills/`
> for Claude Code, `.agents/skills/` for Antigravity / Codex,
> `.cursor/skills/` for Cursor, `.windsurf/workflows/` for Windsurf).
> Scripts live at `<SKILL_DIR>/<skill-name>/scripts/…`.

```bash
TS_RISK_TIERS=high,medium,low TS_LEVELS=unit,integration,e2e \
  bash <SKILL_DIR>/kiss-test-strategy/scripts/bash/draft-strategy.sh --auto
```

### Answer keys

| Key | Default |
|---|---|
| `TS_RISK_TIERS` | `high,medium,low` |
| `TS_LEVELS` | `unit,integration,e2e` |
| `TS_ENVIRONMENTS` | `dev,staging,prod` |
| `TS_COVERAGE_TARGET` | `80` |
