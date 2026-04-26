---
name: "kiss-tech-research"
description: "Researches technology options for a named decision area (frontend framework, database, messaging, identity, etc.) using WebSearch / WebFetch when available. Produces a pros/cons table + typical cost signal per candidate. Records sources. Does not pick the winner. Use when evaluating technology choices, comparing frameworks or databases, or before writing an ADR for a technology decision."
compatibility: "Requires kiss project structure with .kiss/ directory"
metadata:
  author: "github-kiss"
  source: "agent-skills/kiss-tech-research/kiss-tech-research.md"
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
- `{context.paths.docs}/architecture/intake.md` (constraints)

## Outputs

- `{context.paths.docs}/research/<topic>.md` (one file per topic)

## Context Update

Does not mutate `.kiss/context.yml`.

## Handoffs

- `kiss-adr` references research files as evidence in the
  "Decision" section.

## AI authoring scope

**Does:** pull current facts via WebSearch/WebFetch (when tools
available); summarise 2–4 candidates in a pros/cons table; record
sources with dates fetched.

**Does not:** recommend a winner; invent figures; rely on training
data for versioned facts (licensing, pricing, version numbers).

## Usage

> `<SKILL_DIR>` = the integration's skills root (e.g. `.claude/skills/`
> for Claude Code, `.agents/skills/` for Antigravity / Codex,
> `.cursor/skills/` for Cursor, `.windsurf/workflows/` for Windsurf).
> Scripts live at `<SKILL_DIR>/<skill-name>/scripts/…`.

```bash
TR_TOPIC=database TR_CANDIDATES="PostgreSQL,MySQL,SQL Server,MongoDB" \
  bash <SKILL_DIR>/kiss-tech-research/scripts/bash/draft-research.sh --auto
```

### Answer keys

| Key | Meaning |
|---|---|
| `TR_TOPIC` | decision area (database, frontend, identity, …) — required |
| `TR_CANDIDATES` | comma-separated list — required |
