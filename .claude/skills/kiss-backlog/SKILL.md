---
name: "kiss-backlog"
description: "Maintains the product backlog — an ordered markdown list of user stories / items keyed by priority, with lightweight estimates, acceptance-criteria pointers, and status. Drafts and re-orders the list from priorities the user states; does not decide priority or commit a team to deliver. Use when managing a product backlog, adding user stories, reprioritising features, or preparing for sprint planning."
compatibility: "Requires kiss project structure with .kiss/ directory"
metadata:
  author: "github-kiss"
  source: "agent-skills/kiss-backlog/kiss-backlog.md"
user-invocable: true
disable-model-invocation: false
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
- **No jargon.** Translate domain terms into everyday words with
  concrete examples (avoid MoSCoW, WSJF, RICE, INVEST, story
  points, T-shirt, velocity, MVP). Use plain alternatives:
  "must-have / nice-to-have / maybe-later" for priority,
  "Small / Medium / Large / Extra-Large" for size.
- **Choices, not blank fields.** When yes/no isn't enough, offer
  2-4 lettered options (A/B/C/D) with one-line everyday
  descriptions. Always include "Not sure — pick a sensible default".
- **Always recommend.** State the option you would pick and why in
  one sentence so the user can reply "yes" / "ok" to accept.
- **`not sure` / `skip` triggers a sensible default**, marked
  "(default applied — confirm later)" in the backlog row, and a
  `PODEBT-` entry in `product-debts.md`.

When `KISS_AGENT_MODE=auto` (or `--auto`), skip the questionnaire
entirely: apply sensible defaults and log decisions to the
product-owner agent's decision log.

## Inputs

- `.kiss/context.yml` → `paths.docs`, `paths.specs`, `current.feature`
- `{context.paths.specs}/**/spec.md` — user stories source
- `{context.paths.docs}/product/acceptance.md` — ties items to criteria

## Outputs

- `{context.paths.docs}/product/backlog.md` — the ordered backlog.
- `{context.paths.docs}/product/backlog.extract` — summary counts.

## Context Update

Does not mutate `.kiss/context.yml`.

## Handoffs

- `kiss-roadmap` reads the backlog to propose release windows.
- `kiss-taskify` converts prioritised items into tasks.
- `kiss-tasks-to-issues` emits GitHub issues once the PO approves.
- `kiss-sprint-planning` pulls top-N items into a sprint plan.

## AI authoring scope

This skill **does**: append backlog items, re-order by priority the
user provides, estimate T-shirt sizes the user confirms, link each
item to its spec + acceptance criteria.

This skill **does not**: decide which items to promote / demote,
commit a team to deliver anything, negotiate with stakeholders.

## Usage

> `<SKILL_DIR>` = the integration's skills root (e.g. `.claude/skills/`
> for Claude Code, `.agents/skills/` for Antigravity / Codex,
> `.cursor/skills/` for Cursor, `.windsurf/workflows/` for Windsurf).
> Scripts live at `<SKILL_DIR>/<skill-name>/scripts/…`.

```bash
# Add a new item.
BL_TITLE="Forgot-password flow" BL_PRIORITY=2 BL_SIZE=M BL_STORY_REF="specs/user-auth/spec.md#us-04" \
  bash <SKILL_DIR>/kiss-backlog/scripts/bash/add-item.sh --auto

# Reorder (interactive).
bash <SKILL_DIR>/kiss-backlog/scripts/bash/add-item.sh
```

### Answer keys

| Key | Meaning | Default |
|---|---|---|
| `BL_TITLE` | Item title (user story summary) | *(required)* |
| `BL_PRIORITY` | 1 = highest; integer | `99` |
| `BL_SIZE` | XS / S / M / L / XL | `M` |
| `BL_STATUS` | New / Ready / In progress / Done / Cut | `New` |
| `BL_STORY_REF` | Path or anchor into the spec | empty |

## Interactive flow

For each item: title → priority (1 = highest) → size (XS–XL) → spec
reference → status. Loop with "add another? (y/n)".

## Debt register

File `{context.paths.docs}/product/product-debts.md`, prefix
`PODEBT-`. Log when an item has no priority, no acceptance-criteria
link, or an ambiguous size.

## References

- `references/prioritization-frames.md` — MoSCoW, WSJF, RICE quick
  reference.
- `references/estimation-t-shirt.md` — T-shirt sizing anchors.
