---
name: "kiss-risk-register"
description: "Maintain a project risk register. Identify risks, score likelihood × impact, assign categories and owners, draft mitigation and contingency plans. The AI drafts and maintains the register; humans own the decisions to accept, mitigate, transfer, or avoid each risk."
compatibility: "Requires kiss project structure with .kiss/ directory"
metadata:
  author: "github-kiss"
  source: "agent-skills/kiss-risk-register/kiss-risk-register.md"
user-invocable: true
disable-model-invocation: false
---


## User Input

```text
$ARGUMENTS
```

Consider the user input before proceeding (if not empty).

## Audience and tone (interactive mode)

When `KISS_AGENT_MODE=interactive` (the default), assume the user
has **no technical or project-management background**. Run this
skill as a guided questionnaire:

- **One question at a time.** No walls of questions.
- **Yes / no first.** Phrase so `yes`, `no`, `not sure`, or `skip`
  is a valid answer.
- **No jargon.** Translate to everyday words: "How likely is it to
  happen?" *(A) very unlikely, B) maybe, C) likely, D) almost
  certain, E) not sure)* instead of "Likelihood 1-5"; "How bad if
  it happens?" *(A) tiny inconvenience, B) noticeable, C) hurts the
  project, D) project fails, E) not sure)* instead of "Impact
  1-5". Avoid "mitigation / contingency / risk appetite / RPN"
  — say "what we'll do to stop it" / "what we'll do if it happens
  anyway" / "how much risk we're OK with".
- **Use a pre-mortem prompt.** "Imagine the project failed. In one
  sentence, what's the most likely reason?" produces the top risk
  faster than "list your risks".
- **Choices, not blank fields.** When yes/no isn't enough, offer
  2-4 lettered options (A/B/C/D) with one-line everyday
  descriptions. Always include "Not sure — pick a sensible default".
- **Always recommend.** State the option you would pick and why in
  one sentence so the user can reply "yes" / "ok" to accept.
- **`not sure` / `skip` triggers a sensible default** risk entry,
  marked "(default applied — confirm later)" in `risk-register.md`,
  and a `PMDEBT-` entry in `pm-debts.md`.

When `KISS_AGENT_MODE=auto` (or `--auto`), skip the questionnaire
entirely: surface risks from upstream artefacts (architecture,
security review, change log) and log decisions to the
project-manager agent's decision log.

## Inputs

- `.kiss/context.yml` → `paths.docs`, `current.feature`
- `{context.paths.docs}/project/project-plan.extract` (when present)
  — methodology and critical path hint at category emphasis
- `{context.paths.docs}/architecture/*.md` — technical risk surface
- `{context.paths.docs}/reviews/security-debts.md` (when present)
  — surfaces security risks already flagged

## Outputs

- `{context.paths.docs}/project/risk-register.md` — the register
- `{context.paths.docs}/project/risk-register.extract` — companion
  KEY=VALUE ledger with counts by RAG band

## Context Update

Does not mutate `.kiss/context.yml`.

## Handoffs

- `kiss-status-report` reads open Red/Amber risks to populate the
  "Risks escalated this period" section.
- `kiss-change-control` references risks when assessing CR impact.

## AI authoring scope

This skill is an AI authoring aid. It:

- Drafts risk entries from inputs + user-provided facts.
- Performs a structured **risk pre-mortem** ("imagine this project
  failed — what's the most likely reason?") to surface risks the
  user may not have articulated.
- Computes the score = likelihood × impact and colours by band.
- Appends new risks, updates status of existing ones, and never
  deletes closed risks (they stay in the register for audit).

It does **not**:

- Accept, transfer, avoid, or mitigate a risk on the user's behalf.
- Decide who a risk owner is; it proposes, the user confirms.
- Forecast probabilities without stated assumptions.

## Usage

> `<SKILL_DIR>` = the integration's skills root (e.g. `.claude/skills/`
> for Claude Code, `.agents/skills/` for Antigravity / Codex,
> `.cursor/skills/` for Cursor, `.windsurf/workflows/` for Windsurf).
> Scripts live at `<SKILL_DIR>/<skill-name>/scripts/…`.

```bash
# Interactive — add one risk; the AI asks structured questions.
bash <SKILL_DIR>/kiss-risk-register/scripts/bash/add-risk.sh

# Non-interactive — all keys provided.
RISK_DESCRIPTION="OAuth provider outage" \
RISK_CATEGORY=External \
RISK_LIKELIHOOD=3 \
RISK_IMPACT=4 \
RISK_OWNER=devops-lead \
RISK_MITIGATION="Add fallback IdP" \
RISK_CONTINGENCY="Manual approval flow" \
bash <SKILL_DIR>/kiss-risk-register/scripts/bash/add-risk.sh --auto
```

PowerShell parity: `pwsh <SKILL_DIR>/kiss-risk-register/scripts/powershell/add-risk.ps1 [-Auto] [-Answers FILE] [-DryRun]`.

### Answer keys

| Key | Meaning | Default |
|---|---|---|
| `RISK_DESCRIPTION` | One-line description of the risk | *(required — logs debt if missing)* |
| `RISK_CATEGORY` | Technical / Schedule / Resource / Budget / Scope / External / Other | `Other` |
| `RISK_LIKELIHOOD` | 1 (Rare) – 5 (Almost certain) | `3` |
| `RISK_IMPACT` | 1 (Negligible) – 5 (Critical) | `3` |
| `RISK_OWNER` | Name or role responsible for monitoring | *(required — logs debt if missing)* |
| `RISK_MITIGATION` | What will reduce likelihood or impact | *(required — logs debt if missing)* |
| `RISK_CONTINGENCY` | Backup plan if risk occurs | empty |
| `RISK_STATUS` | Active / Mitigated / Closed | `Active` |

## Scoring matrix

See `references/risk-matrix-scoring.md`. In short:

- Score = likelihood × impact (1–25)
- 15–25 → **Red** (must mitigate immediately)
- 8–14 → **Amber** (plan mitigation)
- 1–7 → **Green** (monitor only)

## Categories

See `references/risk-categories.md`. Categories: Technical,
Schedule, Resource, Budget, Scope, External, Other.

## Interactive flow (when scripts can't run)

For each risk the user wants to add, ask one question at a time:

1. What could go wrong? (description)
2. Category (numbered choice 1–7)
3. Likelihood 1–5
4. Impact 1–5
5. Who owns it?
6. Mitigation?
7. Contingency (optional)?

Then append the entry to `docs/project/risk-register.md` using
`templates/risk-register-template.md` as the structure. Loop by
asking: "Add another risk? (y/n)".

## Debt register

Missing required inputs (description / owner / mitigation) are
logged as `PMDEBT-NN` in
`{context.paths.docs}/project/pm-debts.md`.

## References

- `references/risk-matrix-scoring.md` — scoring + colour bands.
- `references/risk-categories.md` — category descriptions and examples.
- `references/risk-premortem-prompts.md` — prompts for a risk
  pre-mortem when the user is stuck.
