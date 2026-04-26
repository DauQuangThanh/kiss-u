---
name: "kiss-observability-plan"
description: "Drafts the observability plan — logs, metrics, traces, SLIs/SLOs, alerts, dashboards. Produces a design doc + starter dashboard/alert YAML. Does not provision monitoring. Use when setting up monitoring for a project, defining SLOs/SLIs, or planning alerting and observability strategy."
compatibility: "Requires kiss project structure with .kiss/ directory"
metadata:
  author: "github-kiss"
  source: "agent-skills/kiss-observability-plan/kiss-observability-plan.md"
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
- `{context.paths.docs}/architecture/intake.md` (SLA)
- `{context.paths.docs}/architecture/c4-container.md`

## Outputs

- `{context.paths.docs}/operations/monitoring.md`
- `assets/alerts.sample.yml` — alert rules starter
- `assets/dashboard.sample.json` — dashboard starter

## Context Update

Does not mutate `.kiss/context.yml`.

## Handoffs

- `kiss-deployment` reads SLI/SLO to set deploy-time canary bake.
- `kiss-cicd` reads alert definitions to wire post-deploy checks.

## AI authoring scope

**Does:** design three pillars (logs / metrics / traces), propose
SLIs (request latency, error rate, saturation, duration) + SLOs
aligned with the intake SLA, draft alert thresholds.

**Does not:** provision dashboards or alerts; page on-call;
modify infra.

## Usage

> `<SKILL_DIR>` = the integration's skills root (e.g. `.claude/skills/`
> for Claude Code, `.agents/skills/` for Antigravity / Codex,
> `.cursor/skills/` for Cursor, `.windsurf/workflows/` for Windsurf).
> Scripts live at `<SKILL_DIR>/<skill-name>/scripts/…`.

```bash
MON_STACK=otel bash <SKILL_DIR>/kiss-observability-plan/scripts/bash/draft-monitoring.sh --auto
```

### Answer keys

| Key | Default |
|---|---|
| `MON_STACK` (`otel`/`datadog`/`newrelic`/`cloudwatch`/`prometheus-grafana`) | `otel` |
| `MON_SLO_AVAILABILITY` | `99.9` |
| `MON_SLO_P95_MS` | `300` |
