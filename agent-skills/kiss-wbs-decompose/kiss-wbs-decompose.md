---
name: kiss-wbs-decompose
description: >-
  Decomposes the project plan's Work Breakdown Structure (WBS) into a
  set of feature directories, writes a stub spec.md for each WBS leaf
  node, and updates .kiss/feature.json to point at the first feature.
  Acts as the bridge between programme-level planning (kiss-project-
  planning) and feature-level specification (kiss-specify). Use when
  a Waterfall project plan exists and the team needs to fan out the
  WBS into individual feature folders so that kiss-specify, kiss-plan,
  and kiss-implement can be run feature by feature.
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

Consider the user input before proceeding (if not empty). If the
user specifies a WBS section or level (e.g. "only Phase 2"), scope
the decomposition to that subset.

## Audience and tone (interactive mode)

When `KISS_AGENT_MODE=interactive` (the default), assume the user
has **limited technical background and limited domain knowledge**.
Run this skill as a guided questionnaire:

- **One question at a time.** No walls of questions.
- **Yes / no first.** Phrase so `yes`, `no`, `not sure`, or `skip`
  is a valid answer.
- **Translate jargon, don't strip it.** Explain WBS, leaf node,
  feature scope on first use.
- **Choices, not blank fields.** Offer lettered options (A/B/C/D).
  Always include "Not sure — sensible default".
- **Always recommend.** State which option you would pick and why.
- **Show, don't ask.** When the WBS is already in the plan, propose
  the parsed feature list and ask for confirmation.
- **`not sure` / `skip` triggers a sensible default**, marked
  "(default applied)" and a WBSDEBT entry.

When `KISS_AGENT_MODE=auto`, skip the questionnaire and log
decisions.

## Inputs

- `.kiss/context.yml`
- `{context.paths.docs}/project/project-plan.md` — WBS section
  (required; if absent, prompt user to run `/kiss.project-planning`
  first, then return here)
- `{context.paths.docs}/project/project-plan.extract` — structured
  KEY=VALUE from the planning skill
- `{context.paths.specs}/` — scanned for existing feature directories
  to avoid duplicates

## Outputs

- One new feature directory per WBS leaf:
  `{context.paths.specs}/<NNN>-<slug>/spec.md` — stub spec with
  the WBS item's title, work package ID, and parent path pre-filled.
  The stub is intentionally minimal; `/kiss.specify` refines it.
- `{context.paths.docs}/project/wbs-index.md` — master table
  mapping WBS ID → feature directory → status
- `{context.paths.docs}/project/wbs-index.extract` — companion
  KEY=VALUE ledger (WBS_LEAF_COUNT, FEATURE_DIRS_CREATED)
- `{context.paths.docs}/project/wbs-debts.md` — WBS items that
  could not be auto-decomposed (WBSDEBT-NN: …)

## Context Update

Does not mutate `.kiss/context.yml` directly.
Writes `.kiss/feature.json` to point at the first generated feature
directory, so the next `/kiss.specify` picks it up automatically.

## Handoffs

- `/kiss.specify` refines each stub spec into a full specification.
- `kiss-srs` aggregates all specs produced from the stubs into the
  SRS.
- `kiss-traceability-matrix` uses the WBS IDs from `wbs-index.md`
  as a cross-reference column.

## AI authoring scope

**Does:**

- Parse the WBS section of `project-plan.md` to find all leaf
  nodes (items with no sub-items, or items at the user-confirmed
  decomposition level).
- Generate a slug (2-4 words, kebab-case) and a sequential
  prefix (NNN) for each leaf.
- Write a stub `spec.md` from `templates/wbs-spec-stub.md` with
  the WBS ID, title, parent WBS path, and a reminder to run
  `/kiss.specify`.
- Skip directories that already exist (idempotent).

**Does not:**

- Fill in full functional requirements — that is `/kiss.specify`'s job.
- Modify `project-plan.md`.
- Delete or overwrite existing spec directories.

## Outline

1. **Load plan** — read `project-plan.md`. If not found, stop and
   prompt the user to run `/kiss.project-planning` first.

2. **Parse WBS** — extract all items from the WBS section.
   In interactive mode, show the parsed leaf list and ask:
   a. Are these the correct leaf nodes to decompose? (yes / edit)
   b. Should summary/phase nodes also get stubs? (default: no)
   c. Should the sequential prefix restart from the current
      max existing number in `specs/`? (default: yes)

3. **Check for duplicates** — scan `{context.paths.specs}/` for
   directories whose names contain the same slug. Skip any matches
   and note them.

4. **Generate stubs** — for each confirmed leaf node:
   - Compute next available NNN prefix.
   - Generate slug from WBS item title.
   - Write `{paths.specs}/<NNN>-<slug>/spec.md` from the stub template.

5. **Write wbs-index.md** — one row per leaf:
   WBS ID | Title | Feature Dir | Status (Stub / In Progress / Done).

6. **Write .kiss/feature.json** pointing at the first stub.

7. **Summary** — print:
   - N stubs created, M skipped (already exist).
   - wbs-index.md location.
   - Next action: run `/kiss.specify` for each feature in order.

## Usage

> `<SKILL_DIR>` = the integration's skills root.

```bash
WBS_DECOMPOSE_LEVEL=3 \
WBS_INCLUDE_SUMMARIES=false \
  bash <SKILL_DIR>/kiss-wbs-decompose/scripts/bash/decompose-wbs.sh --auto
```

### Answer keys

| Key | Meaning | Default |
|---|---|---|
| `WBS_DECOMPOSE_LEVEL` | Max WBS depth to treat as leaf | `3` |
| `WBS_INCLUDE_SUMMARIES` | `true` / `false` — also stub summary nodes | `false` |
| `WBS_PREFIX_RESET` | `true` / `false` — restart NNN from max existing | `true` |
