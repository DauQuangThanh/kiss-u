---
name: "kiss-acceptance-criteria"
description: "Authors Given/When/Then acceptance criteria for user stories. Drafts criteria from the spec and lets the user refine them; does not approve or sign off. Produces the single file that testers and product-owner both reference. Use when writing acceptance criteria, defining what \"done\" means for a story, or when user stories need Given/When/Then format."
compatibility: "Requires kiss project structure with .kiss/ directory"
metadata:
  author: "github-kiss"
  source: "agent-skills/kiss-acceptance-criteria/kiss-acceptance-criteria.md"
---


## User Input

```text
$ARGUMENTS
```

## Audience and tone (interactive mode)

When `KISS_AGENT_MODE=interactive` (the default), assume the user
has **no technical or business-domain background**. Run this skill
as a guided questionnaire:

- **One question at a time.** No walls of questions.
- **Yes / no first.** Phrase so `yes`, `no`, `not sure`, or `skip`
  is a valid answer.
- **No jargon.** Translate domain terms into everyday words. Don't
  ask "give me Given / When / Then" — ask "When the feature works,
  what's the **simplest test** a user can do to prove it? What
  would clearly fail it?" Then *you* turn it into Given / When /
  Then in the file.
- **Choices, not blank fields.** When yes/no isn't enough, offer
  2-4 lettered options (A/B/C/D) with one-line everyday
  descriptions. Always include "Not sure — pick a sensible default".
- **Always recommend.** State the option you would pick and why in
  one sentence so the user can reply "yes" / "ok" to accept.
- **`not sure` / `skip` triggers a sensible default** acceptance
  criterion, marked "(default applied — confirm later)" in
  `acceptance.md`, and a `PODEBT-` entry in `product-debts.md`.

When `KISS_AGENT_MODE=auto` (or `--auto`), skip the questionnaire
entirely: draft criteria from the spec and log assumptions to the
product-owner agent's decision log.

## Inputs

- `.kiss/context.yml` → `paths.docs`, `paths.specs`, `current.feature`
- `{context.paths.specs}/**/spec.md` — user stories source

## Outputs

- `{context.paths.docs}/product/acceptance.md` — all acceptance
  criteria keyed by user-story id.
- `{context.paths.docs}/product/acceptance.extract` — counts of
  stories covered / missing.

## Context Update

Does not mutate `.kiss/context.yml`.

## Handoffs

- `kiss-test-cases` consumes acceptance criteria to generate
  test cases.
- `kiss-backlog` links each backlog item to its acceptance entry.

## AI authoring scope

**Does:** draft Given/When/Then criteria from the spec's user
stories; propose edge-case criteria; log stories with no criteria
as debts.

**Does not:** approve or sign off criteria; commit to scope; decide
what "done" means without user confirmation.

## Usage

> `<SKILL_DIR>` = the integration's skills root (e.g. `.claude/skills/`
> for Claude Code, `.agents/skills/` for Antigravity / Codex,
> `.cursor/skills/` for Cursor, `.windsurf/workflows/` for Windsurf).
> Scripts live at `<SKILL_DIR>/<skill-name>/scripts/…`.

```bash
# Re-draft acceptance criteria for the active feature from spec.md.
bash <SKILL_DIR>/kiss-acceptance/scripts/bash/draft-acceptance.sh --auto
```

## Interactive flow

Read the active feature's `spec.md`. For each user story (US-NN):

1. Propose 2–4 Given/When/Then criteria covering the happy path
   and obvious edge cases.
2. Ask the user to accept / edit / add more.
3. Write into `docs/product/acceptance.md` under a heading matching
   the user-story id.

## Debt register

File `{context.paths.docs}/product/product-debts.md`, prefix
`PODEBT-`. Log when a user story has no criteria, or when criteria
are ambiguous (no measurable outcome).

## References

- `references/gwt-style-guide.md` — how to write Given/When/Then
  cleanly.
