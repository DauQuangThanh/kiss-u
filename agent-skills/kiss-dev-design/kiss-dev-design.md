---
name: kiss-dev-design
description: >-
  Drafts detailed module / API / data-model / integration design for
  the active feature, under docs/design/<feature>/. Uses the
  architecture intake + ADRs + spec as inputs. Does not commit to
  implementation timelines. Use when designing technical
  implementation, planning module structure, or before coding starts
  on a new feature.
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
- `{context.paths.specs}/<feature>/spec.md`
- `{context.paths.docs}/architecture/intake.md`
- `{context.paths.docs}/architecture/c4-container.md`
- `{context.paths.docs}/decisions/ADR-*.md`
- `{context.paths.plans}/<feature>/plan.md` (if `kiss-plan` run)

## Outputs

- `{context.paths.docs}/design/<feature>/design.md`
- `{context.paths.docs}/design/<feature>/api-contract.md` (optional)
- `{context.paths.docs}/design/<feature>/data-model.md` (optional)

## Context Update

Does not mutate `.kiss/context.yml`.

## Handoffs

- `kiss-unit-tests` generates test skeletons from the design's
  module boundaries.
- `kiss-implement` uses the design as the reference for tasks.
- `kiss-test-cases` aligns feature-level tests to the API contract.

## AI authoring scope

**Does:** sketch module structure (hexagonal / onion / MVC as
appropriate), draft API contract (endpoint list + schemas), draft
data-model (tables / collections + relationships), call out
cross-cutting concerns (auth, logging, tracing, feature flags).

**Does not:** commit to an implementation schedule, choose a
library the ADRs haven't covered, assume a pattern the user hasn't
confirmed.

## Usage

> `<SKILL_DIR>` = the integration's skills root (e.g. `.claude/skills/`
> for Claude Code, `.agents/skills/` for Antigravity / Codex,
> `.cursor/skills/` for Cursor, `.windsurf/workflows/` for Windsurf).
> Scripts live at `<SKILL_DIR>/<skill-name>/scripts/…`.

```bash
DD_PATTERN=hexagonal DD_API_STYLE=rest bash <SKILL_DIR>/kiss-dev-design/scripts/bash/draft-design.sh --auto
```

### Answer keys

| Key | Meaning | Default |
|---|---|---|
| `DD_PATTERN` | hexagonal / onion / layered / mvc / clean | `hexagonal` |
| `DD_API_STYLE` | rest / graphql / grpc / trpc / event | `rest` |
| `DD_DATA_STYLE` | relational / document / key-value / mixed | `relational` |
| `DD_INCLUDE_API_CONTRACT` | `true` / `false` | `true` |
| `DD_INCLUDE_DATA_MODEL` | `true` / `false` | `true` |

## References

- `references/design-patterns.md` — hexagonal vs. onion vs. layered
  vs. clean, with a one-line pros/cons.
