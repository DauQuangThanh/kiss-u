---
name: "kiss-test-execution"
description: "Maintains a test-execution ledger for the active feature. Records pass / fail / skipped counts per run, links failed cases to bug reports, and summarises coverage against acceptance criteria. The AI records; the tester runs the tests. Use when logging test run results, tracking pass/fail status, or linking failed tests to bug reports."
compatibility: "Requires kiss project structure with .kiss/ directory"
metadata:
  author: "github-kiss"
  source: "agent-skills/kiss-test-execution/kiss-test-execution.md"
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
- `{context.paths.docs}/testing/<feature>/test-cases.md`
- Raw results the user pastes in or points at (JUnit XML, TAP,
  plain text)

## Outputs

- `{context.paths.docs}/testing/<feature>/execution.md` — one
  section per run.
- `{context.paths.docs}/testing/<feature>/execution.extract` —
  last-run summary.

## Context Update

Does not mutate `.kiss/context.yml`.

## Handoffs

- `kiss-bug-report` reads the failed TC id to link the bug back
  to the execution run.
- `kiss-status-report` reads the last-run summary.

## AI authoring scope

**Does:** append a dated section to the execution ledger,
summarise counts, mark cases pass/fail/skipped, link failures to
bug reports, never delete previous runs.

**Does not:** execute tests, generate results, modify code.

## Usage

> `<SKILL_DIR>` = the integration's skills root (e.g. `.claude/skills/`
> for Claude Code, `.agents/skills/` for Antigravity / Codex,
> `.cursor/skills/` for Cursor, `.windsurf/workflows/` for Windsurf).
> Scripts live at `<SKILL_DIR>/<skill-name>/scripts/…`.

```bash
TE_RUN_DATE=2026-04-24 TE_PASSED=42 TE_FAILED=3 TE_SKIPPED=1 TE_NOTES="CI run, staging env" \
  bash <SKILL_DIR>/kiss-test-execution/scripts/bash/log-run.sh --auto
```

### Answer keys

| Key | Meaning | Default |
|---|---|---|
| `TE_RUN_DATE` | run date | today |
| `TE_PASSED` | pass count | *(required)* |
| `TE_FAILED` | fail count | `0` |
| `TE_SKIPPED` | skipped count | `0` |
| `TE_FAILED_TC_IDS` | comma-separated TC ids that failed | empty |
| `TE_NOTES` | free text | empty |
