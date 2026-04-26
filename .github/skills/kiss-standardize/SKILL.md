---
name: "kiss-standardize"
description: "Creates or updates the project standards from interactive or provided principle inputs, ensuring all dependent templates stay in sync. Use when defining coding standards, setting project conventions, or establishing style guidelines for a new or existing project."
compatibility: "Requires kiss project structure with .kiss/ directory"
metadata:
  author: "github-kiss"
  source: "agent-skills/kiss-standardize/kiss-standardize.md"
---


## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Audience and tone (interactive mode)

When `KISS_AGENT_MODE=interactive` (the default), assume the user
has **no technical or project-management background**. Run this
skill as a guided questionnaire:

- **One question at a time.** No walls of questions.
- **Yes / no first.** Phrase so `yes`, `no`, `not sure`, or `skip`
  is a valid answer.
- **No jargon.** Translate to everyday words: ask "How should we
  agree on what 'good code' looks like?" not "What's the linting
  policy?"; "How often should someone double-check the work?" not
  "What's the review cadence?"; "How will we know we're done?" not
  "What's the Definition of Done?".
- **Choices, not blank fields.** When yes/no isn't enough, offer
  2-4 lettered options (A/B/C/D) with one-line everyday
  descriptions. Always include "Not sure — pick a sensible default".
- **Always recommend.** State the option you would pick and why in
  one sentence so the user can reply "yes" / "ok" to accept.
- **`not sure` / `skip` triggers a sensible default** standard,
  marked "(default applied — confirm later)" in the standards
  document, and a `PMDEBT-` entry in `pm-debts.md`.

When `KISS_AGENT_MODE=auto` (or `--auto`), skip the questionnaire
entirely: apply industry-standard defaults and log decisions to
the project-manager agent's decision log.

## Pre-Execution Checks

**Check for extension hooks (before standards update)**:

- Check if `.kiss/extensions.yml` exists in the project root.
- If it exists, read it and look for entries under the `hooks.before_standardize` key
- If the YAML cannot be parsed or is invalid, skip hook checking silently and continue normally
- Filter out hooks where `enabled` is explicitly `false`. Treat hooks without an `enabled` field as enabled by default.
- For each remaining hook, do **not** attempt to interpret or evaluate hook `condition` expressions:
  - If the hook has no `condition` field, or it is null/empty, treat the hook as executable
  - If the hook defines a non-empty `condition`, skip the hook and leave condition evaluation to the HookExecutor implementation
- For each executable hook, output the following based on its `optional` flag:
  - **Optional hook** (`optional: true`):

    ```text
    ## Extension Hooks

    **Optional Pre-Hook**: {extension}
    Command: `/{command}`
    Description: {description}

    Prompt: {prompt}
    To execute: `/{command}`
    ```

  - **Mandatory hook** (`optional: false`):

    ```text
    ## Extension Hooks

    **Automatic Pre-Hook**: {extension}
    Executing: `/{command}`
    EXECUTE_COMMAND: {command}

    Wait for the result of the hook command before proceeding to the Outline.
    ```

- If no hooks are registered or `.kiss/extensions.yml` does not exist, skip silently

## Outline

You are updating the project standards at `{context.paths.docs}/standards.md`. This file is a TEMPLATE containing placeholder tokens in square brackets (e.g. `[PROJECT_NAME]`, `[PRINCIPLE_1_NAME]`). Your job is to (a) collect/derive concrete values, (b) fill the template precisely, and (c) propagate any amendments across dependent artifacts.

**Note**: If `{context.paths.docs}/standards.md` does not exist yet, initialize it from `templates/standard-template.md` (creating `{context.paths.docs}/` if needed) before proceeding.

Follow this execution flow:

1. Load the existing standards at `{context.paths.docs}/standards.md`.
   - Identify every placeholder token of the form `[ALL_CAPS_IDENTIFIER]`.
   **IMPORTANT**: The user might require less or more principles than the ones used in the template. If a number is specified, respect that - follow the general template. You will update the doc accordingly.

2. Collect/derive values for placeholders:
   - If user input (conversation) supplies a value, use it.
   - Otherwise infer from existing repo context (README, docs, prior standards versions if embedded).
   - For governance dates: `RATIFICATION_DATE` is the original adoption date (if unknown ask or mark TODO), `LAST_AMENDED_DATE` is today if changes are made, otherwise keep previous.
   - `STANDARDS_VERSION` must increment according to semantic versioning rules:
     - MAJOR: Backward incompatible governance/principle removals or redefinitions.
     - MINOR: New principle/section added or materially expanded guidance.
     - PATCH: Clarifications, wording, typo fixes, non-semantic refinements.
   - If version bump type ambiguous, propose reasoning before finalizing.

3. Draft the updated standards content:
   - Replace every placeholder with concrete text (no bracketed tokens left except intentionally retained template slots that the project has chosen not to define yet—explicitly justify any left).
   - Preserve heading hierarchy and comments can be removed once replaced unless they still add clarifying guidance.
   - Ensure each Principle section: succinct name line, paragraph (or bullet list) capturing non‑negotiable rules, explicit rationale if not obvious.
   - Ensure Governance section lists amendment procedure, versioning policy, and compliance review expectations.

4. Consistency propagation checklist (convert prior checklist into active validations):
   - Read `templates/plan-template.md` and ensure any "Standards Check" or rules align with updated principles.
   - Read `templates/spec-template.md` for scope/requirements alignment—update if standards add/remove mandatory sections or constraints.
   - Read `templates/task-template.md` and ensure task categorization reflects new or removed principle-driven task types (e.g., observability, versioning, testing discipline).
   - Read any runtime guidance docs (e.g., `README.md`, `docs/quickstart.md`, or agent-specific guidance files if present). Update references to principles changed.

5. Produce a Sync Impact Report (prepend as an HTML comment at top of the standards file after update):
   - Version change: old → new
   - List of modified principles (old title → new title if renamed)
   - Added sections
   - Removed sections
   - Templates requiring updates (✅ updated / ⚠ pending) with file paths
   - Follow-up TODOs if any placeholders intentionally deferred.

6. Validation before final output:
   - No remaining unexplained bracket tokens.
   - Version line matches report.
   - Dates ISO format YYYY-MM-DD.
   - Principles are declarative, testable, and free of vague language ("should" → replace with MUST/SHOULD rationale where appropriate).

7. Write the completed standards back to `{context.paths.docs}/standards.md` (overwrite).

8. Output a final summary to the user with:
   - New version and bump rationale.
   - Any files flagged for manual follow-up.
   - Suggested commit message (e.g., `docs: amend standards to vX.Y.Z (principle additions + governance update)`).

Formatting & Style Requirements:

- Use Markdown headings exactly as in the template (do not demote/promote levels).
- Wrap long rationale lines to keep readability (<100 chars ideally) but do not hard enforce with awkward breaks.
- Keep a single blank line between sections.
- Avoid trailing whitespace.

If the user supplies partial updates (e.g., only one principle revision), still perform validation and version decision steps.

If critical info missing (e.g., ratification date truly unknown), insert `TODO(<FIELD_NAME>): explanation` and include in the Sync Impact Report under deferred items.

Do not create a new template; always operate on the existing `{context.paths.docs}/standards.md` file.

## Post-Execution Checks

**Check for extension hooks (after standards update)**:
Check if `.kiss/extensions.yml` exists in the project root.

- If it exists, read it and look for entries under the `hooks.after_standardize` key
- If the YAML cannot be parsed or is invalid, skip hook checking silently and continue normally
- Filter out hooks where `enabled` is explicitly `false`. Treat hooks without an `enabled` field as enabled by default.
- For each remaining hook, do **not** attempt to interpret or evaluate hook `condition` expressions:
  - If the hook has no `condition` field, or it is null/empty, treat the hook as executable
  - If the hook defines a non-empty `condition`, skip the hook and leave condition evaluation to the HookExecutor implementation
- For each executable hook, output the following based on its `optional` flag:
  - **Optional hook** (`optional: true`):

    ```text
    ## Extension Hooks

    **Optional Hook**: {extension}
    Command: `/{command}`
    Description: {description}

    Prompt: {prompt}
    To execute: `/{command}`
    ```

  - **Mandatory hook** (`optional: false`):

    ```text
    ## Extension Hooks

    **Automatic Hook**: {extension}
    Executing: `/{command}`
    EXECUTE_COMMAND: {command}
    ```

- If no hooks are registered or `.kiss/extensions.yml` does not exist, skip silently

## Inputs

- **Principles Input** (`user_input`): user_input.
  - If set: Use the provided principles for the standards.
  - If null: Ask the user to provide project principles interactively.
  - If not provided: Ask the user; standards cannot be generated without principles.

## Outputs

- **Project Standards** (`{context.paths.docs}/standards.md`): paths.docs}/standards.md.
  - Behavior: Write the standards file. If it exists and confirm_before_write is true, ask the user.
  - Overwrite guarded by `{context.preferences.confirm_before_write}`.

## Context Update

After this skill completes successfully, update `.kiss/context.yml`:

- Do not update context.yml (standards is a project-level document, not workflow context)

## Handoffs

- **Build Specification**: run `/kiss-specify` to continue the workflow.
