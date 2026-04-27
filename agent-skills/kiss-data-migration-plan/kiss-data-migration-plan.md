---
name: kiss-data-migration-plan
description: >-
  Drafts the data migration plan for a project that replaces or
  upgrades a system with existing data. Covers migration strategy
  (Big Bang / Phased / Parallel Run / Trickle), source-to-target
  field mapping, data quality rules, extraction/transformation/load
  (ETL) outline, cutover window, rollback triggers, reconciliation
  approach, and post-migration validation checklist. Does not execute
  migrations or modify databases. Use when a Waterfall project
  involves migrating data from a legacy system, when a customer
  requires a formal migration runbook, or when data continuity is a
  contractual obligation.
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
has **limited technical background and limited domain knowledge**.
Run this skill as a guided questionnaire:

- **One question at a time.** No walls of questions.
- **Yes / no first.** Phrase so `yes`, `no`, `not sure`, or `skip`
  is a valid answer.
- **No jargon.** Say "moving data from the old system to the new
  one" not "ETL pipeline"; "checking the data arrived correctly"
  not "reconciliation"; "when to stop and go back" not "rollback
  trigger".
- **Choices, not blank fields.** Offer lettered options (A/B/C/D).
  Always include "Not sure — sensible default".
- **Always recommend.** State which option you would pick and why.
- **`not sure` / `skip` triggers a sensible default**, marked
  "(default applied)" and a DMDEBT entry.

When `KISS_AGENT_MODE=auto`, skip the questionnaire and log
decisions.

## Migration strategies

| Strategy | Description | When to use |
|---|---|---|
| Big Bang | All data moved in a single cutover window (downtime required) | Small dataset; short acceptable downtime |
| Phased | Data migrated in batches by domain or date range | Large dataset; partial go-live acceptable |
| Parallel Run | Old and new systems run simultaneously; data kept in sync | Zero downtime required; high risk tolerance needed |
| Trickle (CDC) | Continuous replication using Change Data Capture until cutover | Very large dataset; near-zero downtime |

## Inputs

- `.kiss/context.yml`
- `{context.paths.docs}/analysis/srs.md` — data entities,
  volumes, retention rules (FR-NNN / NFR-NNN related to data)
- `{context.paths.docs}/architecture/intake.md` — legacy system
  description, technology stack
- `{context.paths.docs}/design/<feature>/data-model.md` — target
  data model (if produced by kiss-dev-design)
- `{context.paths.docs}/project/risk-register.md` — data-related
  risks

## Outputs

- `{context.paths.docs}/analysis/data-migration-plan.md` — the
  migration strategy and scope (primary artefact; owned by
  business-analyst)
- `{context.paths.docs}/analysis/field-mapping.md` — source-to-
  target field mapping table (business logic; owned by
  business-analyst)
- `{context.paths.docs}/operations/migration-runbook.md` — step-by-
  step cutover runbook (technical execution; owned by DevOps)
- `{context.paths.docs}/analysis/data-migration-plan.extract` —
  companion KEY=VALUE ledger
  (DM_STRATEGY, DM_CUTOVER_WINDOW, DM_ROLLBACK_TRIGGER,
   DM_RECORD_VOLUME, DM_VALIDATION_APPROACH)
- `{context.paths.docs}/analysis/dm-debts.md` — open items
  (DMDEBT-NN: …)

## Context Update

Does not mutate `.kiss/context.yml`.

## Handoffs

- `kiss-phase-gate` (orr / go-live gate) checks whether the
  migration plan is complete and the dry-run result is documented.
- `kiss-baseline` can snapshot field-mapping.md as part of the
  design baseline.
- `kiss-test-strategy` should include a data-validation test tier
  for the migration; this plan feeds that tier.
- `kiss-risk-register` should capture migration-specific risks
  (data loss, downtime over-run, rollback complexity).
- `kiss-deployment-strategy` is read to align the migration cutover
  window with the deployment window.

## AI authoring scope

**Does:**

- Draft the migration strategy selection with rationale.
- Produce a source-to-target field mapping table from the data model
  and SRS entities.
- Define data quality rules (null handling, type coercion, dedup,
  encoding, date formats).
- Outline ETL steps at the logical level (extract, transform,
  validate, load, verify).
- Define cutover window, rollback triggers, and rollback procedure.
- Produce a post-migration reconciliation checklist.

**Does not:**

- Write ETL code or SQL scripts.
- Access any database or data file.
- Execute or schedule any migration step.

## Outline

1. **Determine scope** — from user input, or ask:
   a. What is the source system? (name, type, rough record count)
   b. What data must be migrated? (all / subset by date / subset by
      entity)
   c. Is downtime acceptable? (yes / no / limited window)

2. **Interactive questionnaire** (interactive mode only):
   a. Source system type: A) relational DB, B) file system / CSV,
      C) another SaaS, D) mix.
   b. Record volume: A) < 100K, B) 100K–1M, C) 1M–100M, D) > 100M.
   c. Migration strategy preference (see table above).
   d. Cutover window: A) weekend maintenance, B) overnight weekday,
      C) business hours with parallel run, D) not decided.
   e. Rollback trigger: A) any reconciliation failure, B) > X%
      failure rate, C) manual decision only.
   f. Privacy / compliance: does the migrated data contain PII,
      financial data, or health records? (affects encryption and
      audit requirements).

3. **Draft field mapping** — for each target entity in the data
   model, map source fields to target fields, noting:
   - Data type transformation needed (e.g. VARCHAR → UUID)
   - Nullable / required differences
   - Default value for missing source data
   - Transformation rule (concatenate, split, lookup, generate)
   Mark unmapped fields as DMDEBT entries.

4. **Define data quality rules**:
   - Null handling policy per critical field
   - Duplicate detection strategy
   - Character encoding (UTF-8 requirement)
   - Date / time zone normalisation
   - Referential integrity checks

5. **Outline ETL process** (logical, not code):
   - Extract: source query / export mechanism, incremental vs full
   - Transform: rule application order, error handling
   - Load: batch size, idempotency strategy, index rebuild
   - Verify: record count match, sample spot-checks, checksum

6. **Define cutover plan**:
   - Freeze point (when writes to old system stop)
   - Migration window duration estimate
   - Rollback decision point and trigger
   - Communication plan for downtime

7. **Draft migration runbook** — step-by-step numbered procedures
   for the cutover team, including go / no-go decision checkpoints.

8. **Post-migration validation checklist** — items the team must
   verify within 24 h of cutover before decommissioning the source.

9. **Write outputs** — write plan, field mapping, runbook, and
   extract.

10. **Summary** — print strategy, estimated cutover window,
    unmapped field count (DMDEBT), and recommended next action.

## Usage

> `<SKILL_DIR>` = the integration's skills root.

```bash
DM_STRATEGY="phased" \
DM_SOURCE="legacy-mysql-5.7" \
DM_RECORD_VOLUME="500000" \
DM_CUTOVER_WINDOW="2026-07-05T22:00/2026-07-06T06:00" \
  bash <SKILL_DIR>/kiss-data-migration-plan/scripts/bash/draft-dm-plan.sh --auto
```

### Answer keys

| Key | Meaning | Default |
|---|---|---|
| `DM_STRATEGY` | `big-bang` / `phased` / `parallel` / `trickle` | `big-bang` |
| `DM_SOURCE` | Source system description | *(ask in interactive)* |
| `DM_RECORD_VOLUME` | Approximate total record count | *(ask in interactive)* |
| `DM_CUTOVER_WINDOW` | ISO interval `start/end` | *(ask in interactive)* |
| `DM_ROLLBACK_TRIGGER` | `any-failure` / `threshold` / `manual` | `any-failure` |
| `DM_HAS_PII` | `true` / `false` — data contains PII | `false` |
