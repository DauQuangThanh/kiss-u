---
name: kiss-baseline
description: >-
  Snapshots the current state of requirements, design, or test
  artefacts as a named, immutable baseline under docs/baselines/.
  Tags the git repository at the same point so the snapshot is
  permanently reachable in version history. Pairs with kiss-change-
  control: the baseline is the "from" state any change request must
  reference. Use after a Requirements (SRR) or Architecture (CDR)
  phase-gate passes, when a customer requests a formal freeze, or
  when a change-control board (CCB) needs a reference snapshot.
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
argument names a baseline type (e.g. `requirements`, `design`,
`test`, `release`) or a label (e.g. `v1.0-srs`), use it directly.

## Audience and tone (interactive mode)

When `KISS_AGENT_MODE=interactive` (the default), assume the user
has **limited technical background and limited domain knowledge**.
Run this skill as a guided questionnaire:

- **One question at a time.** No walls of questions.
- **Yes / no first.** Phrase so `yes`, `no`, `not sure`, or `skip`
  is a valid answer.
- **Translate jargon, don't strip it.** Explain baseline, freeze,
  git tag, change-control reference on first use.
- **Choices, not blank fields.** Offer lettered options (A/B/C/D).
  Always include "Not sure — sensible default".
- **Always recommend.** State which option you would pick and why.
- **Show, don't ask.** Pre-fill from upstream artefacts.
- **`not sure` / `skip` triggers a sensible default**, marked
  "(default applied)" and a BASEDEBT entry.

When `KISS_AGENT_MODE=auto`, skip the questionnaire and log
decisions.

## Baseline types

| Type | Artefacts included | When to use |
|---|---|---|
| `requirements` | srs.md, all spec.md files, srs.extract | After SRR gate passes |
| `design` | srs.md, all design/*.md, ADRs, C4 diagrams | After CDR gate passes |
| `test` | test-strategy, test-cases, quality-gates | After TRR gate passes |
| `release` | all of the above + tasks, deployment-strategy | After ORR / Go-Live gate |
| `custom` | user-specified list of files | Any point in time |

## Inputs

- `.kiss/context.yml`
- Source artefacts for the chosen baseline type (see table above)
- `{context.paths.docs}/project/project-plan.extract` —
  project name, revision context
- Git repository state (commit SHA, current branch)

## Outputs

- `{context.paths.docs}/baselines/<label>/manifest.md` — manifest
  listing every snapshotted file with its SHA-256 hash, source path,
  and baseline date
- `{context.paths.docs}/baselines/<label>/manifest.extract` —
  companion KEY=VALUE ledger
  (BASELINE_LABEL, BASELINE_TYPE, BASELINE_DATE, GIT_TAG, FILE_COUNT)
- Frozen copies of all included artefacts placed under
  `{context.paths.docs}/baselines/<label>/artefacts/`
- A git tag `baseline/<label>` pointing at the current HEAD

## Context Update

Does not mutate `.kiss/context.yml`.

## Handoffs

- `kiss-change-control` references the baseline label in every
  change request to indicate which version is being changed.
- `kiss-phase-gate` can call this skill at the end of a gate
  checklist to freeze the deliverables.
- `kiss-status-report` mentions the active baseline label in the
  project status narrative.

## AI authoring scope

**Does:**

- Determine which files to include based on baseline type.
- Compute SHA-256 hashes of each file.
- Copy artefacts under the baseline directory.
- Write the manifest.
- Instruct the user to run the git tag command (or run it if the
  user confirms git write permission).

**Does not:**

- Modify any source artefact.
- Force-push tags or alter existing baselines.
- Delete old baselines.

## Outline

1. **Determine baseline type and label**:
   - From user input, or ask:
     A) requirements, B) design, C) test, D) release, E) custom.
   - Label default: `<type>-v<date>` (e.g. `requirements-v2026-05-01`).

2. **Collect file list** — based on type, resolve the list of
   files to snapshot. In interactive mode, show the list and ask
   for confirmation or additions.

3. **Verify files exist** — for any missing file, raise a BASEDEBT
   entry and ask whether to proceed without it.

4. **Copy artefacts** to `docs/baselines/<label>/artefacts/`
   preserving relative paths.

5. **Write manifest** — one row per file: source path, destination
   path, SHA-256, size.

6. **Git tag** — output the exact command the user should run:

   ```sh
   git tag -a baseline/<label> -m "Baseline <label> — <type> phase"
   ```

   In auto mode with `BASELINE_GIT_TAG_AUTO=true`, run the command
   directly.

7. **Write outputs** — manifest.md, manifest.extract.

8. **Summary** — print:
   - Baseline label, type, date, file count.
   - Git tag command (if not auto-run).
   - Next suggested action.

## Usage

> `<SKILL_DIR>` = the integration's skills root.

```bash
BASELINE_TYPE="requirements" \
BASELINE_LABEL="requirements-v2026-05-01" \
BASELINE_GIT_TAG_AUTO=false \
  bash <SKILL_DIR>/kiss-baseline/scripts/bash/create-baseline.sh --auto
```

### Answer keys

| Key | Meaning | Default |
|---|---|---|
| `BASELINE_TYPE` | `requirements` / `design` / `test` / `release` / `custom` | *(required)* |
| `BASELINE_LABEL` | Directory / tag name | `<type>-v<YYYY-MM-DD>` |
| `BASELINE_GIT_TAG_AUTO` | `true` / `false` — create git tag automatically | `false` |
| `BASELINE_EXTRA_FILES` | Colon-separated extra file paths to include | *(empty)* |
