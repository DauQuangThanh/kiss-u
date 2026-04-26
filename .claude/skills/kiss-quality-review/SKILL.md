---
name: "kiss-quality-review"
description: "Review a feature's code for maintainability, SOLID/DRY/KISS compliance, cyclomatic complexity, and adherence to project standards. Produces a feature-scoped review file with findings, severity, and recommended fixes. Does not modify code."
compatibility: "Requires kiss project structure with .kiss/ directory"
metadata:
  author: "github-kiss"
  source: "agent-skills/kiss-quality-review/kiss-quality-review.md"
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
- Source files changed for `current.feature`
- `{context.paths.docs}/architecture/intake.md`
- Project standards (from `kiss-standardize` output)

## Outputs

- `{context.paths.docs}/reviews/<feature>/quality.md`
- `{context.paths.docs}/reviews/<feature>/quality.extract`

## Context Update

Does not mutate `.kiss/context.yml`.

## Handoffs

- `bug-fixer` reads findings with severity ≥ High to drive fixes.
- `kiss-standardize` is updated when recurring violations indicate
  a missing standard.

## AI authoring scope

**Does:** read source files, cite exact file:line refs for each
finding, score complexity, flag SOLID/DRY/KISS violations, propose
a fix outline per finding.

**Does not:** refactor code (bug-fixer / developer applies fixes),
assign findings to individuals.

## Usage

> `<SKILL_DIR>` = the integration's skills root (e.g. `.claude/skills/`
> for Claude Code, `.agents/skills/` for Antigravity / Codex,
> `.cursor/skills/` for Cursor, `.windsurf/workflows/` for Windsurf).
> Scripts live at `<SKILL_DIR>/<skill-name>/scripts/…`.

```bash
QR_SCOPE="src/**/*.ts" bash <SKILL_DIR>/kiss-quality-review/scripts/bash/review.sh --auto
```

### Answer keys

| Key | Meaning | Default |
|---|---|---|
| `QR_SCOPE` | glob of files to review | `src/**` |
| `QR_MAX_CYCLOMATIC` | threshold for complexity finding | `10` |
| `QR_MAX_FUNCTION_LINES` | threshold for long-function finding | `50` |

## References

- `references/solid-dry-kiss.md` — canonical definitions + smell
  signals.
- `references/complexity-thresholds.md` — per-language guidance.
