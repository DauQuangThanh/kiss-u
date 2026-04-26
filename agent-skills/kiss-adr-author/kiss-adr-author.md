---
name: kiss-adr-author
description: >-
  Authors Architecture Decision Records (ADRs) in the Michael Nygard
  template. One ADR per file, auto-numbered, lives under
  docs/decisions/. Records the decision the user made — does not
  make decisions. Use when recording a technical choice, documenting
  why a technology or design approach was selected, or when a
  decision needs a permanent, reviewable record.
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
- `{context.paths.docs}/architecture/intake.md`
- `{context.paths.docs}/research/*.md`

## Outputs

- `{context.paths.docs}/decisions/ADR-NNN-<slug>.md`

## Context Update

Does not mutate `.kiss/context.yml`.

## Handoffs

- `kiss-c4-diagrams` cross-links ADRs from container-level
  diagrams where the decision manifests in the architecture.
- `kiss-arch-extraction` (technical-analyst) references existing
  ADRs when reverse-engineering a codebase.

## AI authoring scope

**Does:** scaffold the ADR with the template, pre-fill
context/consequences from linked research, record Status =
"Proposed" until the user updates it to "Accepted".

**Does not:** accept or supersede an ADR on the user's behalf;
declare something "the decision" unless the user stated it.

## Usage

> `<SKILL_DIR>` = the integration's skills root (e.g. `.claude/skills/`
> for Claude Code, `.agents/skills/` for Antigravity / Codex,
> `.cursor/skills/` for Cursor, `.windsurf/workflows/` for Windsurf).
> Scripts live at `<SKILL_DIR>/<skill-name>/scripts/…`.

```bash
ADR_TITLE="Choose PostgreSQL as primary store" \
ADR_DECIDER="tech-lead" \
ADR_CONTEXT="Need ACID + relational joins" \
ADR_DECISION="Use PostgreSQL 16 on managed RDS" \
ADR_CONSEQUENCES="Vendor lock-in to AWS RDS; HA story via Multi-AZ" \
ADR_STATUS="Proposed" \
  bash <SKILL_DIR>/kiss-adr-author/scripts/bash/add-adr.sh --auto
```

### Answer keys

| Key | Meaning | Default |
|---|---|---|
| `ADR_TITLE` | decision title | *(required)* |
| `ADR_DECIDER` | person / role making the call | *(required)* |
| `ADR_CONTEXT` | situation + forces | *(required → log debt if empty)* |
| `ADR_DECISION` | what was decided | *(required → log debt if empty)* |
| `ADR_CONSEQUENCES` | trade-offs accepted | empty |
| `ADR_STATUS` | `Proposed` / `Accepted` / `Deprecated` / `Superseded` | `Proposed` |
| `ADR_SUPERSEDES` | ADR id this replaces | empty |
