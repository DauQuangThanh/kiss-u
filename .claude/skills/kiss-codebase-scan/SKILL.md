---
name: "kiss-codebase-scan"
description: "Scan an existing codebase and produce an overview: language + LOC by directory, detected frameworks, entry points, test coverage signals, build/lint/format tooling. Input for all other technical- analyst skills."
compatibility: "Requires kiss project structure with .kiss/ directory"
metadata:
  author: "github-kiss"
  source: "agent-skills/kiss-codebase-scan/kiss-codebase-scan.md"
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

- Project root files (package.json, pyproject.toml, go.mod, …)
- Source tree under `src/`, `lib/`, `app/`, …

## Outputs

- `{context.paths.docs}/analysis/codebase-scan.md`
- `{context.paths.docs}/analysis/codebase-scan.extract`

## Context Update

Does not mutate `.kiss/context.yml`.

## Handoffs

- `kiss-arch-extraction` starts from this scan.
- `kiss-api-docs` narrows to detected HTTP / RPC frameworks.
- `kiss-dependency-map` uses the LOC + entry-point list.

## AI authoring scope

**Does:** classify files by extension, count LOC per top-level
dir, detect primary language(s), detect frameworks (web, test,
build, lint), find entry points (`main.*`, `server.*`,
`index.*`).

**Does not:** modify files, run tests, push anything.

## Usage

> `<SKILL_DIR>` = the integration's skills root (e.g. `.claude/skills/`
> for Claude Code, `.agents/skills/` for Antigravity / Codex,
> `.cursor/skills/` for Cursor, `.windsurf/workflows/` for Windsurf).
> Scripts live at `<SKILL_DIR>/<skill-name>/scripts/…`.

```bash
bash <SKILL_DIR>/kiss-codebase-scan/scripts/bash/scan.sh --auto
```

### Answer keys

| Key | Default |
|---|---|
| `CS_EXCLUDE_GLOBS` | `node_modules/**,dist/**,.venv/**,build/**,target/**` |
