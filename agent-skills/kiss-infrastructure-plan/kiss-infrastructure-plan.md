---
name: kiss-infrastructure-plan
description: >-
  Drafts infrastructure-as-code plan — cloud accounts, networks,
  compute/storage/database resources, IAM boundaries. Produces a
  tool-neutral design + a starter module for the chosen IaC tool.
  Does not provision anything. Use when planning cloud infrastructure,
  designing IaC with Terraform or Bicep, or defining network and
  compute topology.
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
- `{context.paths.docs}/architecture/intake.md` (cloud preference,
  compliance regime)
- `{context.paths.docs}/architecture/c4-container.md` (compute +
  storage needs)

## Outputs

- `{context.paths.docs}/operations/infra.md`
- `{context.paths.docs}/operations/infra.extract`
- `assets/infra-starter.tf` or `assets/infra-starter.bicep` —
  tool-specific starter module.

## Context Update

Does not mutate `.kiss/context.yml`.

## Handoffs

- `kiss-containerization` reads compute decisions.
- `kiss-monitoring` reads network topology.
- `kiss-deployment` reads environment layout.
- `kiss-cicd` reads deploy targets.

## AI authoring scope

**Does:** design the resource tree (accounts / subscriptions →
networks → compute / storage / data), IAM boundaries, per-env
separation. Draft a starter module in the chosen tool.

**Does not:** run `terraform apply`, create cloud resources,
store credentials.

## Usage

> `<SKILL_DIR>` = the integration's skills root (e.g. `.claude/skills/`
> for Claude Code, `.agents/skills/` for Antigravity / Codex,
> `.cursor/skills/` for Cursor, `.windsurf/workflows/` for Windsurf).
> Scripts live at `<SKILL_DIR>/<skill-name>/scripts/…`.

```bash
INFRA_TOOL=terraform INFRA_CLOUD=aws bash <SKILL_DIR>/kiss-infrastructure-plan/scripts/bash/draft-infra.sh --auto
```

### Answer keys

| Key | Default |
|---|---|
| `INFRA_TOOL` (`terraform`/`opentofu`/`bicep`/`pulumi`/`cloudformation`) | `terraform` |
| `INFRA_CLOUD` (`aws`/`azure`/`gcp`/`on-prem`/`multi`) | `aws` |
| `INFRA_ENVS` | `dev,staging,prod` |
