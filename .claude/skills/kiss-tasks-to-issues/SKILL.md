---
name: "kiss-tasks-to-issues"
description: "Converts existing tasks into actionable, dependency-ordered GitHub issues for the feature based on available design artefacts. Use when creating GitHub issues from tasks.md, exporting tasks to a GitHub project board, or when the team tracks work in GitHub Issues."
argument-hint: "Optional filter or label for GitHub issues"
compatibility: "Requires kiss project structure with .kiss/ directory"
metadata:
  author: "github-kiss"
  source: "agent-skills/kiss-tasks-to-issues/kiss-tasks-to-issues.md"
user-invocable: true
disable-model-invocation: false
---


## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Audience and tone (interactive mode)

When `KISS_AGENT_MODE=interactive` (the default), assume the user
has **no technical or business-domain background**. Run this skill
as a guided questionnaire:

- **One question at a time.** No walls of questions.
- **Yes / no first.** Phrase so `yes`, `no`, `not sure`, or `skip`
  is a valid answer.
- **No jargon.** Translate domain terms into everyday words. Don't
  ask "promote tasks to issues with labels" — ask "want me to
  create a separate to-do (issue) on GitHub for each task in the
  list?".
- **Choices, not blank fields.** When yes/no isn't enough, offer
  2-4 lettered options (A/B/C/D) with one-line everyday
  descriptions. Always include "Not sure — pick a sensible default".
- **Always recommend.** State the option you would pick and why in
  one sentence so the user can reply "yes" / "ok" to accept.
- **Confirm before pushing to GitHub.** Show the full list of
  issues you'll create (titles + bodies + labels) and ask
  "Create [N] issues on GitHub? (yes / no / change which?)".
  Never auto-create.
- **`not sure` / `skip` triggers a sensible default**: skip the
  ambiguous task, mark it "(default applied — confirm later)" in
  `tasks.md`, and log a debt entry in the parent agent's debt
  file.

When `KISS_AGENT_MODE=auto` (or `--auto`), skip the conversational
gate but still: show the list and require a single "go ahead"
before any GitHub write.

## Pre-Execution Checks

**Check for extension hooks (before tasks-to-issues conversion)**:

- Check if `.kiss/extensions.yml` exists in the project root.
- If it exists, read it and look for entries under the `hooks.before_tasks-to-issues` key
- If the YAML cannot be parsed or is invalid, skip hook checking silently and continue normally
- Filter out hooks where `enabled` is explicitly `false`. Treat hooks without an `enabled` field as enabled by default.
- For each remaining hook, do **not** attempt to interpret or evaluate hook `condition` expressions:
  - If the hook has no `condition` field, or it is null/empty, treat the hook as executable
  - If the hook defines a non-empty `condition`, skip the hook and leave condition evaluation to the HookExecutor implementation
- When constructing slash commands from hook command names, replace dots (`.`) with hyphens (`-`). For example, `kiss.git.commit` → `/kiss-git-commit`.
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

1. Run `scripts/bash/check-prerequisites.sh --json --require-tasks --include-tasks` from repo root and parse FEATURE_DIR and AVAILABLE_DOCS list. All paths must be absolute. For single quotes in args like "I'm Groot", use escape syntax: e.g 'I'\''m Groot' (or double-quote if possible: "I'm Groot").
1. From the executed script, extract the path to **tasks**.
1. Get the Git remote by running:

```bash
git config --get remote.origin.url
```

> [!CAUTION]
> ONLY PROCEED TO NEXT STEPS IF THE REMOTE IS A GITHUB URL

1. For each task in the list, use the GitHub MCP server to create a new issue in the repository that is representative of the Git remote.

> [!CAUTION]
> UNDER NO CIRCUMSTANCES EVER CREATE ISSUES IN REPOSITORIES THAT DO NOT MATCH THE REMOTE URL

## Post-Execution Checks

**Check for extension hooks (after tasks-to-issues conversion)**:
Check if `.kiss/extensions.yml` exists in the project root.

- If it exists, read it and look for entries under the `hooks.after_tasks-to-issues` key
- If the YAML cannot be parsed or is invalid, skip hook checking silently and continue normally
- Filter out hooks where `enabled` is explicitly `false`. Treat hooks without an `enabled` field as enabled by default.
- For each remaining hook, do **not** attempt to interpret or evaluate hook `condition` expressions:
  - If the hook has no `condition` field, or it is null/empty, treat the hook as executable
  - If the hook defines a non-empty `condition`, skip the hook and leave condition evaluation to the HookExecutor implementation
- When constructing slash commands from hook command names, replace dots (`.`) with hyphens (`-`). For example, `kiss.git.commit` → `/kiss-git-commit`.
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

- **Tasks List** (`{context.current.tasks}`): current.tasks.
  - If set: Read the tasks file.
  - If null: Search {context.paths.tasks} for the most recent tasks.md.
  - If not provided: Error: tasks file is required. Run /kiss-taskify first.

## Outputs

- **GitHub Issues** (`GitHub repository`): github repository.
  - Behavior: Create GitHub issues for each task. Requires GitHub API access (mcp tool: github/github-mcp-server/issue_write).
  - Overwrite guarded by `{context.preferences.confirm_before_write}`.

## Context Update

After this skill completes successfully, update `.kiss/context.yml`:

- Do not update context.yml (issue creation is external system sync)
