---
name: "kiss-dependency-audit"
description: "Audit third-party dependencies: list direct + transitive deps, cross-reference against CVE databases (via WebSearch/WebFetch), surface licence conflicts and abandonware. Records audit as a dated file so subsequent runs show drift."
compatibility: "Requires kiss project structure with .kiss/ directory"
metadata:
  author: "github-kiss"
  source: "agent-skills/kiss-dependency-audit/kiss-dependency-audit.md"
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
- Project lockfiles (package-lock.json, uv.lock, poetry.lock,
  go.sum, Cargo.lock, pom.xml, Gemfile.lock, …)

## Outputs

- `{context.paths.docs}/reviews/<feature>/dependencies.md`
- `{context.paths.docs}/reviews/<feature>/dependencies.extract`

## Context Update

Does not mutate `.kiss/context.yml`.

## Handoffs

- `kiss-security-review` Category A06 cites this file.
- `bug-fixer` reads Critical / High CVEs to drive fixes.
- `kiss-cicd` mirrors the audit as a pipeline stage.

## AI authoring scope

**Does:** enumerate direct + transitive deps from the right
lockfile, fetch current CVE data via `WebSearch`/`WebFetch`,
flag licence conflicts against project policy, propose upgrade
paths.

**Does not:** upgrade packages, edit lockfiles, claim "no
vulnerabilities" without a citation.

## Usage

> `<SKILL_DIR>` = the integration's skills root (e.g. `.claude/skills/`
> for Claude Code, `.agents/skills/` for Antigravity / Codex,
> `.cursor/skills/` for Cursor, `.windsurf/workflows/` for Windsurf).
> Scripts live at `<SKILL_DIR>/<skill-name>/scripts/…`.

```bash
bash <SKILL_DIR>/kiss-dependency-audit/scripts/bash/audit.sh --auto
```

### Answer keys

| Key | Meaning | Default |
|---|---|---|
| `DA_LICENCE_POLICY` | allow-list, comma-separated | `MIT,Apache-2.0,BSD-3-Clause,BSD-2-Clause,ISC` |
| `DA_MAX_AGE_DAYS` | flag deps untouched for this many days | `730` |
