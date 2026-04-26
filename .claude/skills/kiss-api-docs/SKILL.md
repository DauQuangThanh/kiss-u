---
name: "kiss-api-docs"
description: "Generate API documentation from source code: list endpoints / RPC methods / queue topics with their schemas and auth. Works backward from routes + OpenAPI / proto / gql definitions."
compatibility: "Requires kiss project structure with .kiss/ directory"
metadata:
  author: "github-kiss"
  source: "agent-skills/kiss-api-docs/kiss-api-docs.md"
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
- `{context.paths.docs}/analysis/codebase-scan.md`
- Route modules + OpenAPI / proto / GraphQL schema files

## Outputs

- `{context.paths.docs}/analysis/api-docs.md`
- `{context.paths.docs}/analysis/api-docs.extract`

## Context Update

Does not mutate `.kiss/context.yml`.

## Handoffs

- `kiss-dev-design` (architect / developer) references api-docs
  when evolving contracts.
- `kiss-security-review` uses the endpoint list for authZ review.

## AI authoring scope

**Does:** enumerate endpoints, include request / response
schemas, auth requirement, error responses; annotate with source
`file:line`.

**Does not:** invent routes; guess schemas where the code doesn't
declare them; hit live endpoints.

## Usage

> `<SKILL_DIR>` = the integration's skills root (e.g. `.claude/skills/`
> for Claude Code, `.agents/skills/` for Antigravity / Codex,
> `.cursor/skills/` for Cursor, `.windsurf/workflows/` for Windsurf).
> Scripts live at `<SKILL_DIR>/<skill-name>/scripts/…`.

```bash
API_STYLE=rest bash <SKILL_DIR>/kiss-api-docs/scripts/bash/generate-api-docs.sh --auto
```

### Answer keys

| Key | Default |
|---|---|
| `API_STYLE` (`rest`/`graphql`/`grpc`/`trpc`/`events`) | `rest` |
