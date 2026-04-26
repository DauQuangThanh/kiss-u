---
name: "kiss-unit-tests"
description: "Generates unit-test skeletons for the active feature from the design + acceptance criteria. Writes test files into the project's own test tree (not under docs/). Covers the happy path, negative branches, and at least one boundary per function. Use when writing unit tests, generating test skeletons for a feature, or when test coverage needs to be added for new code."
compatibility: "Requires kiss project structure with .kiss/ directory"
metadata:
  author: "github-kiss"
  source: "agent-skills/kiss-unit-tests/kiss-unit-tests.md"
user-invocable: true
disable-model-invocation: false
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
- `{context.paths.docs}/design/<feature>/design.md`
- `{context.paths.docs}/design/<feature>/api-contract.md` (if present)
- `{context.paths.docs}/product/acceptance.md` (for AC-linked tests)

## Outputs

- Test files under the project's own test directory (`tests/`,
  `spec/`, `__tests__/`, etc. — the AI picks the right location).
- `{context.paths.docs}/testing/<feature>/unit-tests-index.md` —
  a per-feature index listing generated test files, the function
  they cover, and which AC they trace to.
- `{context.paths.docs}/testing/<feature>/unit-tests-index.extract`

## Context Update

Does not mutate `.kiss/context.yml`. Does not run tests — it
scaffolds them.

## Handoffs

- `kiss-implement` executes the tasks that fill in test bodies
  when skeletons alone are not enough.
- `kiss-test-cases` (feature-level Given/When/Then) complements
  unit tests with end-to-end scenarios.
- `kiss-test-execution` records results.

## AI authoring scope

**Does:** infer target language/framework from the project (check
`package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`), scaffold
one test file per module boundary, include a happy-path, a negative
case, and at least one boundary per public function, leave
intentional `// TODO` markers where a decision is deferred.

**Does not:** run the tests; invent business rules not present in
the design or acceptance criteria; replace tests the developer has
already written.

## Usage

> `<SKILL_DIR>` = the integration's skills root (e.g. `.claude/skills/`
> for Claude Code, `.agents/skills/` for Antigravity / Codex,
> `.cursor/skills/` for Cursor, `.windsurf/workflows/` for Windsurf).
> Scripts live at `<SKILL_DIR>/<skill-name>/scripts/…`.

```bash
UT_FRAMEWORK=vitest UT_TARGET_DIR=tests \
  bash <SKILL_DIR>/kiss-unit-tests/scripts/bash/scaffold-tests.sh --auto
```

### Answer keys

| Key | Meaning | Default |
|---|---|---|
| `UT_FRAMEWORK` | `vitest`/`jest`/`pytest`/`go-test`/`junit`/`xunit`/`rspec`… | auto-detected from project files |
| `UT_TARGET_DIR` | project-root-relative test dir | auto-detected |
| `UT_MIN_COVERAGE` | informational threshold to log into the index | `80` |

## Interactive flow

1. Detect language + framework from project files.
2. Read `design.md` modules — one test file per top-level module.
3. For each public function, propose: happy path + 1–2 negatives +
   1 boundary. List them in the index file, then scaffold.
4. Link each test back to an AC id (if any) so coverage → AC is
   traceable.

## Debt register

File: `{context.paths.docs}/testing/<feature>/test-debts.md`,
prefix `TQDEBT-`. Log when:

- A module has no public functions to test.
- A function has no clear happy path stated.
- Framework auto-detection fails.

## References

- `references/framework-detection.md` — how the script decides.
