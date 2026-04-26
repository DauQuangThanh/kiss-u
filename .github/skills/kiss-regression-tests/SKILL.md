---
name: "kiss-regression-tests"
description: "Authors a regression test per fixed bug so the same defect cannot ship again without being caught. Writes test files into the project's own test tree + a per-bug index entry at docs/testing/regression-index.md. Use when a bug has been fixed and needs a regression test, or when preventing a defect from silently reappearing in future releases."
compatibility: "Requires kiss project structure with .kiss/ directory"
metadata:
  author: "github-kiss"
  source: "agent-skills/kiss-regression-tests/kiss-regression-tests.md"
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
- `{context.paths.docs}/bugs/change-register.md`

## Outputs

- Test files under the project's own test tree (framework-specific).
- `{context.paths.docs}/testing/regression-index.md` — one row
  per bug → test file.

## Context Update

Does not mutate `.kiss/context.yml`.

## Handoffs

- `kiss-change-register` links the fix commit to the regression
  test once the fix lands.
- `kiss-bug-triage` reads the regression index to verify every
  closed bug has coverage.

## AI authoring scope

**Does:** scaffold one regression test per fixed bug, targeting
the exact repro steps from the bug file, leave the expected
assertions explicit.

**Does not:** run tests, close bugs, modify production code.

## Usage

> `<SKILL_DIR>` = the integration's skills root (e.g. `.claude/skills/`
> for Claude Code, `.agents/skills/` for Antigravity / Codex,
> `.cursor/skills/` for Cursor, `.windsurf/workflows/` for Windsurf).
> Scripts live at `<SKILL_DIR>/<skill-name>/scripts/…`.

```bash
RT_BUG_ID=BUG-014 bash <SKILL_DIR>/kiss-regression-tests/scripts/bash/scaffold-regression.sh --auto
```

### Answer keys

| Key | Meaning | Default |
|---|---|---|
| `RT_BUG_ID` | the bug to scaffold a regression for | *(required)* |
| `RT_LEVEL` | unit / integration / e2e | `integration` |
