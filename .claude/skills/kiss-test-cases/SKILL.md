---
name: "kiss-test-cases"
description: "Generates feature-level test cases from user stories and acceptance criteria. Produces a dependency-ordered test-case file the tester walks through during execution. Use when writing test cases, generating a test plan from acceptance criteria, or before starting test execution for a feature."
compatibility: "Requires kiss project structure with .kiss/ directory"
metadata:
  author: "github-kiss"
  source: "agent-skills/kiss-test-cases/kiss-test-cases.md"
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
- `{context.paths.specs}/<feature>/spec.md`
- `{context.paths.docs}/product/acceptance.md`
- `{context.paths.docs}/testing/<feature>/strategy.md`

## Outputs

- `{context.paths.docs}/testing/<feature>/test-cases.md`

## Context Update

Does not mutate `.kiss/context.yml`.

## Handoffs

- `kiss-test-execution` runs against this list and records results.
- `kiss-bug-report` references the failed TC id when a case fails.

## AI authoring scope

**Does:** enumerate test cases per acceptance criterion, pick
representative positive / negative / boundary cases per AC, tag
each with level (unit / integration / e2e), estimate effort.

**Does not:** run tests, modify code, decide pass/fail.

## Usage

> `<SKILL_DIR>` = the integration's skills root (e.g. `.claude/skills/`
> for Claude Code, `.agents/skills/` for Antigravity / Codex,
> `.cursor/skills/` for Cursor, `.windsurf/workflows/` for Windsurf).
> Scripts live at `<SKILL_DIR>/<skill-name>/scripts/…`.

```bash
bash <SKILL_DIR>/kiss-test-cases/scripts/bash/generate-cases.sh --auto
```

### Answer keys

| Key | Meaning | Default |
|---|---|---|
| `TC_CASES_PER_AC` | cases generated per AC | `3` |
| `TC_INCLUDE_BOUNDARY` | `true` / `false` | `true` |
