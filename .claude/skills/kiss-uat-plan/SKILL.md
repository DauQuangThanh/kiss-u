---
name: "kiss-uat-plan"
description: "Drafts the User Acceptance Testing (UAT) plan for a feature or release. UAT is a customer-owned phase distinct from system testing: it verifies that the delivered system meets business objectives in a production-like environment with real or representative users. Produces scope, entry/exit criteria, environments, participant roster, test scenarios (business-workflow level), execution schedule, sign-off ledger, and defect escalation rules. Does not facilitate the UAT session itself. Use when a Waterfall project approaches the verification phase, when a customer contract requires formal UAT sign-off, or when distinguishing UAT from QA system testing."
compatibility: "Requires kiss project structure with .kiss/ directory"
metadata:
  author: "github-kiss"
  source: "agent-skills/kiss-uat-plan/kiss-uat-plan.md"
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
has **limited technical background and limited domain knowledge**.
Run this skill as a guided questionnaire. UAT participants are often
business stakeholders with no technical background — frame everything
in business-process terms:

- **One question at a time.** No walls of questions.
- **Yes / no first.** Phrase so `yes`, `no`, `not sure`, or `skip`
  is a valid answer.
- **No jargon.** Say "business users trying the system" not "UAT
  participants"; "working the way you expect" not "meets acceptance
  criteria"; "production-like environment" not "staging".
- **Choices, not blank fields.** Offer lettered options (A/B/C/D).
  Always include "Not sure — sensible default".
- **Always recommend.** State which option you would pick and why.
- **`not sure` / `skip` triggers a sensible default**, marked
  "(default applied)" and a UATDEBT entry.

When `KISS_AGENT_MODE=auto`, skip the questionnaire and log
decisions.

## Inputs

- `.kiss/context.yml`
- `{context.paths.specs}/<feature>/spec.md` — user stories and
  acceptance criteria
- `{context.paths.docs}/analysis/srs.md` — FR-NNN / NFR-NNN
  (optional but recommended)
- `{context.paths.docs}/testing/<feature>/strategy.md` — system
  test strategy (to ensure UAT is complementary, not redundant)
- `{context.paths.docs}/testing/<feature>/test-cases.md` — system
  test cases (to identify what is already covered)
- `{context.paths.docs}/operations/deployment-strategy.md` —
  environment availability (optional)

## Outputs

- `{context.paths.docs}/analysis/uat-plan/<feature>/uat-plan.md` —
  the UAT plan (primary artefact)
- `{context.paths.docs}/analysis/uat-plan/<feature>/uat-plan.extract`
  — companion KEY=VALUE ledger
  (UAT_REVISION, UAT_FEATURE, UAT_ENV, UAT_START_DATE, UAT_END_DATE)
- `{context.paths.docs}/analysis/uat-plan/<feature>/uat-sign-off.md`
  — the sign-off ledger the business sponsor and user
  representatives complete after UAT execution
- `{context.paths.docs}/analysis/uat-plan/<feature>/uat-debts.md`
  — open items (UATDEBT-NN: …)

## Context Update

Does not mutate `.kiss/context.yml`.

## Handoffs

- `kiss-test-execution` maintains the execution ledger; UAT runs
  follow the same ledger but with a separate UAT-focused section.
- `kiss-phase-gate` (orr gate) checks whether uat-sign-off.md
  is completed before recommending ORR pass.
- `kiss-bug-report` is used to log defects found during UAT.
- `kiss-deployment-strategy` is read to confirm environment
  readiness.

## AI authoring scope

**Does:**

- Draft business-workflow-level UAT scenarios (not unit tests)
  derived from user stories and acceptance criteria.
- Define participant roles (business sponsor, end-user reps,
  SMEs, UAT coordinator) without naming individuals.
- Specify environment requirements, test data policy, and defect
  severity escalation rules.
- Produce a sign-off ledger with named roles and approval thresholds.

**Does not:**

- Conduct UAT sessions, interview end-users, or collect feedback.
- Decide pass / fail on behalf of the business sponsor.
- Write low-level technical test scripts (that is `kiss-test-cases`).

## Outline

1. **Determine scope** — from user input, or ask:
   a. Which feature or release does UAT cover?
   b. Are there specific business workflows that must be validated?
   c. What does "success" mean for the business sponsor in everyday
      terms?

2. **Interactive questionnaire** (interactive mode only):
   a. UAT environment: A) separate UAT env, B) staging, C) prod
      (with feature flags), D) not sure.
   b. Test data: A) real anonymised data, B) representative
      synthetic data, C) specific datasets the user provides.
   c. Participants: A) internal business users, B) external customers,
      C) a mix — how many?
   d. Duration: A) 1–3 days, B) 1 week, C) 2 weeks, D) longer.
   e. Defect severity thresholds for blocking sign-off.

3. **Draft UAT scenarios** — for each user story in `spec.md`:
   - Write 1–3 business-workflow scenarios (not Given/When/Then — use
     plain numbered steps a business user would follow).
   - Mark which acceptance criteria the scenario validates.
   - Assign priority: Critical (blocks sign-off) / High / Medium.

4. **Define entry and exit criteria**:
   - Entry: system test complete, no open Critical bugs, environment
     ready, test data loaded, participants briefed.
   - Exit: all Critical scenarios passed, open defect counts below
     threshold, business sponsor signs off.

5. **Draft plan document** — fill `templates/uat-plan-template.md`.

6. **Draft sign-off ledger** — fill `templates/uat-sign-off-template.md`.

7. **Write outputs** — write plan, sign-off ledger, and extract.

8. **Summary** — print scenario count, participant roles, schedule
   window, and next action.

## Usage

> `<SKILL_DIR>` = the integration's skills root.

```bash
UAT_FEATURE="payment-checkout" \
UAT_ENV="staging" \
UAT_START_DATE="2026-06-01" \
UAT_END_DATE="2026-06-07" \
  bash <SKILL_DIR>/kiss-uat-plan/scripts/bash/draft-uat.sh --auto
```

### Answer keys

| Key | Meaning | Default |
|---|---|---|
| `UAT_FEATURE` | Feature slug (must match a specs/ dir) | current.feature from context |
| `UAT_ENV` | `staging` / `uat` / `prod` | `staging` |
| `UAT_START_DATE` | ISO date | *(ask in interactive)* |
| `UAT_END_DATE` | ISO date | `UAT_START_DATE + 7 days` |
| `UAT_CRITICAL_THRESHOLD` | Max open Critical defects to pass | `0` |
| `UAT_HIGH_THRESHOLD` | Max open High defects to pass | `3` |
