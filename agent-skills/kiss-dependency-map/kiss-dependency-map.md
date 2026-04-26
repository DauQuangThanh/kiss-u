---
name: kiss-dependency-map
description: >-
  Renders the project's internal module-dependency graph + external
  dependency list as a Mermaid diagram. Works from imports + the
  lockfile produced by kiss-codebase-scan. Use when visualising
  module dependencies, understanding code structure, or identifying
  circular dependencies and coupling.
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
- `{context.paths.docs}/analysis/codebase-scan.md`
- Source imports; project lockfile

## Outputs

- `{context.paths.docs}/analysis/dependencies.md`
- `assets/module-graph.mmd`

## Context Update

Does not mutate `.kiss/context.yml`.

## Handoffs

- `kiss-dependency-audit` extends this with CVEs + licences.
- `kiss-quality-review` flags circular / high-fan-out modules.

## AI authoring scope

**Does:** list top-N internal modules by fan-in + fan-out,
render a Mermaid flowchart, list external deps with versions,
flag circular imports.

**Does not:** modify imports; install / upgrade packages.

## Usage

> `<SKILL_DIR>` = the integration's skills root (e.g. `.claude/skills/`
> for Claude Code, `.agents/skills/` for Antigravity / Codex,
> `.cursor/skills/` for Cursor, `.windsurf/workflows/` for Windsurf).
> Scripts live at `<SKILL_DIR>/<skill-name>/scripts/…`.

```bash
DM_MAX_MODULES=25 bash <SKILL_DIR>/kiss-dependency-map/scripts/bash/build-map.sh --auto
```

### Answer keys

| Key | Default |
|---|---|
| `DM_MAX_MODULES` | `25` |
