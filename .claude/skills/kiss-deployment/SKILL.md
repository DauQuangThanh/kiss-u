---
name: "kiss-deployment"
description: "Draft the deployment strategy + release runbook — canary / blue-green / rolling, promotion flow, rollback, feature flags, release-notes seed. Produces a runbook the on-call team uses. Does not deploy."
compatibility: "Requires kiss project structure with .kiss/ directory"
metadata:
  author: "github-kiss"
  source: "agent-skills/kiss-deployment/kiss-deployment.md"
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
- `{context.paths.docs}/operations/cicd.md`
- `{context.paths.docs}/operations/infra.md`
- `{context.paths.docs}/operations/monitoring.md`
- `{context.paths.docs}/bugs/change-register.md` (for release
  notes)

## Outputs

- `{context.paths.docs}/operations/deployment.md`
- `{context.paths.docs}/operations/release-notes-<date>.md` (on
  each release)

## Context Update

Does not mutate `.kiss/context.yml`.

## Handoffs

- `kiss-pm-planning` references the release model in milestones.
- `kiss-status-report` references the most recent release.
- `kiss-monitoring` is consulted for canary bake thresholds.

## AI authoring scope

**Does:** pick a release model (canary / blue-green / rolling),
draft the promotion flow across environments, specify rollback
criteria + commands, propose feature-flag usage, seed release
notes from the change register.

**Does not:** deploy; run kubectl / terraform / any cloud CLI;
toggle feature flags.

## Usage

> `<SKILL_DIR>` = the integration's skills root (e.g. `.claude/skills/`
> for Claude Code, `.agents/skills/` for Antigravity / Codex,
> `.cursor/skills/` for Cursor, `.windsurf/workflows/` for Windsurf).
> Scripts live at `<SKILL_DIR>/<skill-name>/scripts/…`.

```bash
DP_MODEL=canary DP_CANARY_BAKE_MIN=30 bash <SKILL_DIR>/kiss-deployment/scripts/bash/draft-deployment.sh --auto
```

### Answer keys

| Key | Default |
|---|---|
| `DP_MODEL` (`canary`/`blue-green`/`rolling`/`recreate`) | `canary` |
| `DP_CANARY_BAKE_MIN` | `30` |
| `DP_ENVIRONMENTS` | `dev,staging,prod` |
