---
name: "kiss-cicd"
description: "Draft CI/CD pipeline design for the project — stages, triggers, quality-gate integration, artefact flow. Produces a provider- neutral pipeline doc + a provider-specific YAML skeleton. Does not provision CI; does not run pipelines."
compatibility: "Requires kiss project structure with .kiss/ directory"
metadata:
  author: "github-kiss"
  source: "agent-skills/kiss-cicd/kiss-cicd.md"
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
- `{context.paths.docs}/testing/*/quality-gates.md` (gates per feature)
- `{context.paths.docs}/architecture/c4-container.md` (build units)

## Outputs

- `{context.paths.docs}/operations/cicd.md` — design doc.
- `{context.paths.docs}/operations/cicd.extract`
- `assets/ci-pipeline.sample.yml` — provider-specific starter
  (GitHub Actions / GitLab CI / Azure Pipelines / CircleCI /
  Buildkite).

## Context Update

Does not mutate `.kiss/context.yml`.

## Handoffs

- `kiss-deployment` references the pipeline's release stage.
- `kiss-monitoring` reads the deploy stage to hook alerts.

## AI authoring scope

**Does:** design stage ordering (lint → unit → integration →
security → build → deploy-to-staging → e2e → approve → deploy-to-prod),
draft a YAML skeleton matching the chosen provider.

**Does not:** provision CI; push YAML to the repo; run pipelines.

## Usage

> `<SKILL_DIR>` = the integration's skills root (e.g. `.claude/skills/`
> for Claude Code, `.agents/skills/` for Antigravity / Codex,
> `.cursor/skills/` for Cursor, `.windsurf/workflows/` for Windsurf).
> Scripts live at `<SKILL_DIR>/<skill-name>/scripts/…`.

```bash
CI_PROVIDER=github-actions bash <SKILL_DIR>/kiss-cicd/scripts/bash/draft-cicd.sh --auto
```

### Answer keys

| Key | Meaning | Default |
|---|---|---|
| `CI_PROVIDER` | github-actions / gitlab-ci / azure-pipelines / circleci / buildkite | `github-actions` |
| `CI_REQUIRES_MANUAL_RELEASE` | `true` / `false` | `true` |
