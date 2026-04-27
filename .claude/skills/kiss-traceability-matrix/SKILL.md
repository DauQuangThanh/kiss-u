---
name: "kiss-traceability-matrix"
description: "Builds and maintains a Requirements Traceability Matrix (RTM) that links every requirement (FR-NNN / NFR-NNN from the SRS) to its design section, implementation task, test case, and bug report. Supports forward traceability (requirements → delivery) and backward traceability (artefacts → requirements). Use when a Waterfall project needs to demonstrate that every requirement is designed, implemented, and tested; when a customer or auditor asks for full traceability evidence; or when performing a coverage gap analysis before a phase gate."
compatibility: "Requires kiss project structure with .kiss/ directory"
metadata:
  author: "github-kiss"
  source: "agent-skills/kiss-traceability-matrix/kiss-traceability-matrix.md"
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
Run this skill as a guided questionnaire:

- **One question at a time.** No walls of questions.
- **Yes / no first.** Phrase so `yes`, `no`, `not sure`, or `skip`
  is a valid answer.
- **Translate jargon, don't strip it.** Explain RTM, traceability,
  coverage gap on first use.
- **Choices, not blank fields.** Offer lettered options (A/B/C/D)
  with one-line descriptions. Always include "Not sure — sensible
  default".
- **Always recommend.** State which option you would pick and why.
- **Show, don't ask.** Pre-fill from upstream artefacts; ask for
  yes / no confirmation.
- **`not sure` / `skip` triggers a sensible default**, marked
  "(default applied)" and a RTMDEBT entry.

When `KISS_AGENT_MODE=auto`, skip the questionnaire and log
decisions to the parent agent's decision log.

## Inputs

- `.kiss/context.yml`
- `{context.paths.docs}/analysis/srs.md` — FR-NNN / NFR-NNN
  identifiers (required; if absent, prompt user to run
  `/kiss.srs` first)
- `{context.paths.docs}/analysis/srs.extract` — ID counters
- `{context.paths.docs}/design/**/*.md` — design sections
- `{context.paths.tasks}/**/tasks.md` — task IDs (TASK-NNN)
- `{context.paths.docs}/testing/**/test-cases.md` — test case IDs
  (TC-NNN)
- `{context.paths.docs}/bugs/*.md` — bug report IDs (BUG-NNN)

## Outputs

- `{context.paths.docs}/analysis/traceability-matrix.md` — the RTM
  (primary artefact)
- `{context.paths.docs}/analysis/traceability-matrix.extract` —
  companion KEY=VALUE ledger
  (RTM_REVISION, COVERAGE_PCT, UNCOVERED_REQS, LAST_UPDATED)
- `{context.paths.docs}/analysis/rtm-debts.md` — traceability gaps
  and open items (RTMDEBT-NN: …)

## Context Update

Does not mutate `.kiss/context.yml`.

## Handoffs

- `kiss-phase-gate` reads `traceability-matrix.extract` to verify
  that COVERAGE_PCT meets the gate threshold before sign-off.
- `kiss-test-execution` appends pass/fail status per TC-NNN, which
  updates the RTM's test-result column.
- `kiss-baseline` can snapshot `traceability-matrix.md` as part of
  the verification baseline.

## AI authoring scope

**Does:**

- Parse FR-NNN / NFR-NNN IDs from `srs.md`.
- Scan design docs, tasks, test cases, and bug reports to detect
  links.
- Populate the RTM table and calculate coverage percentages.
- Flag requirements with no design, task, test, or bug link as
  RTMDEBT entries.
- Support incremental update: re-running the skill refreshes
  existing rows rather than overwriting manual edits.

**Does not:**

- Invent or remove design sections, tasks, or test cases.
- Accept the gap as "acceptable" on the user's behalf.
- Modify any source artefact (spec, design, tasks, test cases).

## Outline

1. **Load SRS** — parse `srs.md` for every FR-NNN / NFR-NNN entry.
   If not found, stop and instruct the user to run `/kiss.srs` first.

2. **Discover linked artefacts**:
   - Design: scan `{docs}/design/**/*.md` for headings referencing
     FR-NNN / NFR-NNN.
   - Tasks: scan `tasks.md` files for requirement references.
   - Test cases: scan test-case files for "Covers: FR-NNN" tags.
   - Bugs: scan bug report files for requirement references.

3. **Interactive gap check** (interactive mode only) — if uncovered
   requirements are found, ask:
   a. Do you want to mark them as "Out of Scope" or "Deferred"?
   b. Should a RTMDEBT entry be raised for each gap?

4. **Build / update the RTM table** — one row per requirement ID,
   columns: ID | Title | Priority | Design Ref | Task ID(s) |
   Test Case ID(s) | Test Status | Bug ID(s) | Coverage Status.

5. **Compute coverage metrics**:
   - Coverage % = requirements with ≥1 test case / total requirements.
   - Design coverage % = requirements with ≥1 design ref / total.
   - Task coverage % = requirements with ≥1 task / total.

6. **Write outputs** — write `traceability-matrix.md`,
   `traceability-matrix.extract`, and `rtm-debts.md`.

7. **Summary** — print:
   - Total requirements, coverage %, open gaps.
   - Suggested next action if coverage < 100%.

## Usage

> `<SKILL_DIR>` = the integration's skills root.

```bash
RTM_COVERAGE_THRESHOLD=80 \
  bash <SKILL_DIR>/kiss-traceability-matrix/scripts/bash/build-rtm.sh --auto
```

### Answer keys

| Key | Meaning | Default |
|---|---|---|
| `RTM_COVERAGE_THRESHOLD` | Minimum coverage % to pass a gate | `80` |
| `RTM_INCLUDE_NFRS` | `true` / `false` — include NFRs in RTM | `true` |
