---
name: "kiss-c4-diagrams"
description: "Authors C4 model diagrams (Context / Container / Component) as Mermaid flowcharts. Produces three files per project so the system can be described at every zoom level. Draws what the user has declared; does not invent components. Use when creating architecture diagrams, visualising system structure, or when the project needs Context, Container, or Component-level views."
compatibility: "Requires kiss project structure with .kiss/ directory"
metadata:
  author: "github-kiss"
  source: "agent-skills/kiss-c4-diagrams/kiss-c4-diagrams.md"
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
- `{context.paths.docs}/architecture/intake.md`
- `{context.paths.docs}/decisions/ADR-*.md`

## Outputs

- `{context.paths.docs}/architecture/c4-context.md`
- `{context.paths.docs}/architecture/c4-container.md`
- `{context.paths.docs}/architecture/c4-component.md`

Level 4 (Code) is intentionally omitted — code diagrams belong in
the design skill, not the architecture skill.

## Context Update

Does not mutate `.kiss/context.yml`.

## Handoffs

- `kiss-dev-design` uses container diagrams to identify modules.
- `kiss-security-review` references container diagrams for attack
  surface.
- `kiss-cicd` / `kiss-deployment` reference container diagrams to
  align runtime topology with pipelines.

## AI authoring scope

**Does:** draft Mermaid diagrams using the C4 convention; cite
which actors + systems come from which intake entry.

**Does not:** invent containers or components not stated by the
user or an ADR; redraw on unapproved changes without asking.

## Usage

> `<SKILL_DIR>` = the integration's skills root (e.g. `.claude/skills/`
> for Claude Code, `.agents/skills/` for Antigravity / Codex,
> `.cursor/skills/` for Cursor, `.windsurf/workflows/` for Windsurf).
> Scripts live at `<SKILL_DIR>/<skill-name>/scripts/…`.

```bash
bash <SKILL_DIR>/kiss-c4-diagrams/scripts/bash/draft-c4.sh --auto
```

### Answer keys

| Key | Meaning | Default |
|---|---|---|
| `C4_LEVEL` | `context`, `container`, `component`, or `all` | `all` |
| `C4_SYSTEM_NAME` | the subject system | derived from `current.feature` |

## References

- `references/c4-shorthand.md` — how to draw C4 in plain Mermaid
  (no special plugins required).
- `assets/c4-context-example.mmd`,
  `assets/c4-container-example.mmd` — reference diagrams.
