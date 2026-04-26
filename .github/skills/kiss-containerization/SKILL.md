---
name: "kiss-containerization"
description: "Drafts Dockerfile / compose / image-build strategy for the project. Produces a multi-stage Dockerfile starter, a compose file for local dev, and the design doc. Does not build or push images. Use when dockerising an application, planning a container strategy, or when the project needs Docker or Docker Compose configuration."
compatibility: "Requires kiss project structure with .kiss/ directory"
metadata:
  author: "github-kiss"
  source: "agent-skills/kiss-containerization/kiss-containerization.md"
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
- `{context.paths.docs}/architecture/c4-container.md`
- Project root (to detect language / framework)

## Outputs

- `{context.paths.docs}/operations/containers.md`
- `assets/Dockerfile.sample` — multi-stage starter
- `assets/compose.sample.yml` — local dev compose

## Context Update

Does not mutate `.kiss/context.yml`.

## Handoffs

- `kiss-cicd` reads the build stage in containers.md.
- `kiss-deployment` reads runtime requirements.
- `kiss-security-review` reviews the image base + layers.

## AI authoring scope

**Does:** design multi-stage builds (build → test → runtime),
propose non-root users, size-optimised final stage, healthchecks,
signal handling.

**Does not:** build, push, or deploy images; commit secrets.

## Usage

> `<SKILL_DIR>` = the integration's skills root (e.g. `.claude/skills/`
> for Claude Code, `.agents/skills/` for Antigravity / Codex,
> `.cursor/skills/` for Cursor, `.windsurf/workflows/` for Windsurf).
> Scripts live at `<SKILL_DIR>/<skill-name>/scripts/…`.

```bash
CONT_RUNTIME=node bash <SKILL_DIR>/kiss-containerization/scripts/bash/draft-containers.sh --auto
```

### Answer keys

| Key | Default |
|---|---|
| `CONT_RUNTIME` | detected from project |
| `CONT_BASE_IMAGE` | one of distroless / slim / alpine (default `slim`) |
