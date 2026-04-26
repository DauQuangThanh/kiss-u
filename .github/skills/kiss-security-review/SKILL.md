---
name: "kiss-security-review"
description: "Reviews a feature's code + config against OWASP Top 10:2025 and common CWE patterns. Produces a per-feature security review with findings, severity, and remediation outlines. Does not deploy, write exploits, or modify code. Use when reviewing security posture, checking for OWASP vulnerabilities, or performing a pre-release security audit."
compatibility: "Requires kiss project structure with .kiss/ directory"
metadata:
  author: "github-kiss"
  source: "agent-skills/kiss-security-review/kiss-security-review.md"
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
- Source files changed for `current.feature`
- `{context.paths.docs}/architecture/c4-container.md` (attack
  surface)
- `{context.paths.docs}/architecture/intake.md` (compliance regime)
- `{context.paths.docs}/decisions/ADR-*.md` (auth / crypto choices)

## Outputs

- `{context.paths.docs}/reviews/<feature>/security.md`
- `{context.paths.docs}/reviews/security-debts.md` (append,
  shared across features)

## Context Update

Does not mutate `.kiss/context.yml`.

## Handoffs

- `kiss-dependency-audit` complements with third-party CVE scan.
- `bug-fixer` reads Critical / High severity findings.
- `kiss-status-report` reads `security-debts.extract` for
  escalations.

## AI authoring scope

**Does:** walk each OWASP Top 10:2025 category against the feature's
code and config, identify specific `file:line` findings, outline
remediation per finding, and link to authoritative references (OWASP
cheat sheet, CWE catalogue).

**Does not:** run exploits; pentest live systems; commit to a
"secure / insecure" label without stated assumptions; modify
code.

## Usage

> `<SKILL_DIR>` = the integration's skills root (e.g. `.claude/skills/`
> for Claude Code, `.agents/skills/` for Antigravity / Codex,
> `.cursor/skills/` for Cursor, `.windsurf/workflows/` for Windsurf).
> Scripts live at `<SKILL_DIR>/<skill-name>/scripts/…`.

```bash
SR_COMPLIANCE="gdpr,soc2" bash <SKILL_DIR>/kiss-security-review/scripts/bash/review.sh --auto
```

### Answer keys

| Key | Meaning | Default |
|---|---|---|
| `SR_SCOPE` | glob of files to review | `src/**` |
| `SR_COMPLIANCE` | comma list (gdpr / hipaa / pci-dss / soc2 / iso27001) | empty |
| `SR_THREAT_MODEL` | `stride` / `linddun` / `none` | `stride` |

## References

- `references/owasp-top10-2025.md` — the ten categories + smell
  patterns + remediation outlines.
- `references/stride-guide.md` — STRIDE threat-modelling questions.
