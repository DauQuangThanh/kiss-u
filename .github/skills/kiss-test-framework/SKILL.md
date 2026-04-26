---
name: "kiss-test-framework"
description: "Recommends unit + integration + e2e frameworks that fit the project's language + architecture, drafts the folder layout, and lists the tooling versions. Use when choosing a test framework, setting up testing infrastructure, or defining the test toolchain for a new project or language stack."
compatibility: "Requires kiss project structure with .kiss/ directory"
metadata:
  author: "github-kiss"
  source: "agent-skills/kiss-test-framework/kiss-test-framework.md"
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
- `{context.paths.docs}/architecture/intake.md`
- `{context.paths.docs}/testing/<feature>/strategy.md`
- Project root files (package.json, pyproject.toml, go.mod, …)

## Outputs

- `{context.paths.docs}/testing/<feature>/framework.md`
- `{context.paths.docs}/testing/<feature>/framework.extract`

## Context Update

Does not mutate `.kiss/context.yml`.

## Handoffs

- `kiss-unit-tests` reads the unit framework choice.
- `kiss-test-cases` reads the e2e framework choice.
- `kiss-cicd` reads framework commands when drafting the pipeline.

## AI authoring scope

**Does:** detect language(s) and framework signals, propose 2–3
candidates per level (unit / integration / e2e), draft the folder
layout, list required dev-dependencies.

**Does not:** install packages, edit `package.json`/equivalent,
commit the team to a framework without confirmation.

## Usage

> `<SKILL_DIR>` = the integration's skills root (e.g. `.claude/skills/`
> for Claude Code, `.agents/skills/` for Antigravity / Codex,
> `.cursor/skills/` for Cursor, `.windsurf/workflows/` for Windsurf).
> Scripts live at `<SKILL_DIR>/<skill-name>/scripts/…`.

```bash
bash <SKILL_DIR>/kiss-test-framework/scripts/bash/draft-framework.sh --auto
```

### Answer keys

| Key | Meaning | Default |
|---|---|---|
| `TF_UNIT_FRAMEWORK` | override detected unit framework | auto |
| `TF_INTEGRATION_FRAMEWORK` | override integration framework | same as unit |
| `TF_E2E_FRAMEWORK` | e2e framework | `playwright` (web) / `none` |

## References

- `references/framework-matrix.md` — per-language recommended
  defaults.
