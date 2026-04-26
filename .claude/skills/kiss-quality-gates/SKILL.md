---
name: "kiss-quality-gates"
description: "Define quality gates (coverage thresholds, lint / type / security scan pass criteria, performance budgets) that every PR and every release must pass. Produces a gate definition the CI pipeline enforces. Does not enforce them itself."
compatibility: "Requires kiss project structure with .kiss/ directory"
metadata:
  author: "github-kiss"
  source: "agent-skills/kiss-quality-gates/kiss-quality-gates.md"
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
- `{context.paths.docs}/testing/<feature>/strategy.md`
- `{context.paths.docs}/testing/<feature>/framework.md`

## Outputs

- `{context.paths.docs}/testing/<feature>/quality-gates.md`
- `{context.paths.docs}/testing/<feature>/quality-gates.extract`

## Context Update

Does not mutate `.kiss/context.yml`.

## Handoffs

- `kiss-cicd` reads the gate definitions to shape pipeline stages.
- `kiss-deployment` reads release-level gates.

## AI authoring scope

**Does:** draft gate thresholds per level (PR gate / merge gate /
release gate), list which tools enforce each gate, propose
performance budgets from the intake's operational envelope.

**Does not:** modify CI pipelines, commit thresholds the user
hasn't approved, claim a build passes a gate that it didn't.

## Usage

> `<SKILL_DIR>` = the integration's skills root (e.g. `.claude/skills/`
> for Claude Code, `.agents/skills/` for Antigravity / Codex,
> `.cursor/skills/` for Cursor, `.windsurf/workflows/` for Windsurf).
> Scripts live at `<SKILL_DIR>/<skill-name>/scripts/…`.

```bash
QG_COVERAGE_PR=80 QG_COVERAGE_RELEASE=85 QG_P95_MS=200 \
  bash <SKILL_DIR>/kiss-quality-gates/scripts/bash/draft-gates.sh --auto
```

### Answer keys

| Key | Meaning | Default |
|---|---|---|
| `QG_COVERAGE_PR` | coverage % required on PR | `80` |
| `QG_COVERAGE_RELEASE` | coverage % required for release | `85` |
| `QG_P95_MS` | performance budget — p95 latency | `200` |
| `QG_MAX_HIGH_VULN` | max allowed High-severity CVEs | `0` |
| `QG_MAX_CRIT_VULN` | max allowed Critical CVEs | `0` |
