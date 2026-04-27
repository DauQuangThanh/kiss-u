---
name: kiss-srs
description: >-
  Aggregates all feature specs into a single IEEE 29148:2018-aligned
  System / Software Requirements Specification (SRS). Numbers every
  functional requirement (FR-NNN) and non-functional requirement
  (NFR-NNN), establishes a requirements baseline, and produces the
  sign-off cover sheet. Use when a Waterfall project needs a formal
  consolidated SRS before architecture design begins, when a
  regulatory or contractual deliverable demands a numbered requirement
  set, or when the project requires traceability from business needs
  to design.
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

Consider the user input before proceeding (if not empty).

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
  descriptions. Always include "Not sure — pick a sensible default".
- **Always recommend.** State the option you would pick and why in
  one sentence so the user can reply "yes" / "ok" to accept.
- **Show, don't ask.** When upstream artefacts already imply an
  answer, propose it as a pre-filled finding and ask for confirmation.
- **`not sure` / `skip` triggers a sensible default**, marked
  "(default applied — confirm later)" in the artefact, and a debt
  entry in `srs-debts.md`.

When `KISS_AGENT_MODE=auto` (or `--auto`), skip the questionnaire
entirely: apply sensible defaults from upstream artefacts and log
decisions to the parent agent's decision log.

## Inputs

- `.kiss/context.yml`
- `{context.paths.specs}/**/spec.md` — all feature specifications;
  if none exist, prompt the user to run `kiss-specify` first
- `{context.paths.docs}/project/project-plan.md` — WBS / scope statement
  (optional but recommended)
- `{context.paths.docs}/architecture/intake.md` — quality attributes,
  constraints, NFRs captured during architecture intake (optional)

## Outputs

- `{context.paths.docs}/architecture/srs.md` — the consolidated SRS
  (primary artefact)
- `{context.paths.docs}/architecture/srs.extract` — companion
  KEY=VALUE ledger consumed by downstream skills
  (SRS_REVISION, LAST_FR_ID, LAST_NFR_ID, BASELINE_DATE)
- `{context.paths.docs}/architecture/srs-debts.md` — open items
  the project team must resolve before the SRS is baselined
  (SRSDEBT-NN: …)

## Context Update

Does not mutate `.kiss/context.yml`.

## Handoffs

- `kiss-traceability-matrix` uses FR-NNN / NFR-NNN identifiers from
  `srs.extract` as the requirement column of the RTM.
- `kiss-phase-gate` reads `srs.md` as the Requirements gate deliverable.
- `kiss-arch-intake` may be run before this skill to populate NFRs.
- `kiss-test-strategy` reads NFRs (performance, security, reliability)
  from `srs.md` to determine test tiers.
- `kiss-baseline` can snapshot `srs.md` as the requirements baseline.

## AI authoring scope

**Does:**

- Read every `spec.md` under `{context.paths.specs}/`.
- Extract and number all functional requirements (FR-NNN) and
  non-functional requirements (NFR-NNN) in sequential order,
  preserving the source feature reference.
- Produce a document that conforms to the structure and terminology
  of IEEE 29148:2018 (formerly IEEE 830).
- Flag missing or ambiguous requirements as SRSDEBT entries.
- Insert a sign-off table (Author, Reviewer, Approver) for the user
  to populate.

**Does not:**

- Approve, accept, or baseline the SRS on the user's behalf.
- Invent requirements not traceable to a `spec.md` source.
- Run any tools, modify code, or touch files outside the output
  directory without explicit user confirmation.

## Outline

1. **Gather specs** — scan `{context.paths.specs}/**/spec.md` and
   list the features found. If none, stop and instruct the user to
   run `/kiss.specify` for each feature first.

2. **Interactive questionnaire** (interactive mode only) — ask:
   a. SRS document title and project name (default: project name
      from `project-plan.md` or context, else ask).
   b. Intended audience: A) internal team, B) external customer /
      auditor, C) regulatory body, D) all — affects formality level.
   c. Revision number (default: `1.0`).
   d. Whether to include a traceability stub section (default: yes).
   e. Confirm the feature list detected above is complete.

3. **Requirement extraction** — for each spec:
   - Map each "Functional Requirement" line to a sequentially
     numbered FR-NNN entry in the SRS.
   - Map each NFR (performance, security, reliability, usability,
     maintainability, portability, legal/compliance) to NFR-NNN.
   - Record the source spec slug alongside every identifier.

4. **Draft SRS** — fill `templates/srs-template.md` with:
   - Cover page: title, project, revision, date, sign-off table.
   - Sections 1–6 per IEEE 29148:2018:
     1. Introduction (purpose, scope, definitions, overview)
     2. Overall description (product perspective, assumptions,
        dependencies, constraints)
     3. Functional requirements (FR-001 … FR-NNN), each with:
        priority (MoSCoW), rationale, source spec reference, and
        acceptance criterion stub.
     4. Non-functional requirements (NFR-001 … NFR-NNN), each
        with measurable acceptance criterion, rationale, and
        source spec reference.
     5. External interfaces (UI, API, hardware, communication)
        sourced from spec "User Scenarios" and architecture intake.
     6. Constraints and assumptions.
   - Appendix: open SRSDEBT entries.

5. **Quality check** — after drafting, verify:
   - Every FR / NFR has a measurable acceptance criterion.
   - No orphaned requirements (traceable back to a spec).
   - No duplicate IDs.
   - Log any violations as SRSDEBT entries.

6. **Write outputs** — write `srs.md`, `srs.extract`, and
   `srs-debts.md` (or append to existing).

7. **Summary** — print a one-page summary:
   - Total FRs and NFRs.
   - Number of open SRSDEBT entries.
   - Which features have the most requirements (top 3).
   - Next suggested action: run `/kiss.traceability-matrix` or
     `/kiss.phase-gate`.

## Usage

> `<SKILL_DIR>` = the integration's skills root (e.g. `.claude/skills/`
> for Claude Code, `.agents/skills/` for other agents).

```bash
SRS_TITLE="Acme Payments Platform SRS" \
SRS_REVISION="1.0" \
SRS_AUDIENCE="internal" \
  bash <SKILL_DIR>/kiss-srs/scripts/bash/draft-srs.sh --auto
```

### Answer keys

| Key | Meaning | Default |
|---|---|---|
| `SRS_TITLE` | Document title | `<project-name> Software Requirements Specification` |
| `SRS_REVISION` | Revision string | `1.0` |
| `SRS_AUDIENCE` | `internal` / `external` / `regulatory` / `all` | `internal` |
| `SRS_INCLUDE_TRACE_STUB` | `true` / `false` — include traceability stub section | `true` |
