---
name: "kiss-specify"
description: "Creates or updates the feature specification from a natural language feature description. Use when starting work on a new feature, creating a spec from a user story or idea, or when the feature description needs to be formalised into a structured specification."
argument-hint: "Describe the feature you want to specify"
compatibility: "Requires kiss project structure with .kiss/ directory"
metadata:
  author: "github-kiss"
  source: "agent-skills/kiss-specify/kiss-specify.md"
user-invocable: true
disable-model-invocation: false
---


## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Pre-Execution Checks

**Check for extension hooks (before specification)**:

- Check if `.kiss/extensions.yml` exists in the project root.
- If it exists, read it and look for entries under the `hooks.before_specify` key
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

## Interactive Mode (beginner-friendly questionnaire)

If `KISS_AGENT_MODE=interactive` (the default) **and** the
natural-language feature description is too sparse to populate every
mandatory section of the spec template — for example the user typed
only "build me a booking app" and key facts about users, data,
devices, or success are missing — pause before step 5 of the
Outline and walk the user through the questionnaire below.

Audience: assume the user has **no technical and no business-domain
background**. Tone: friendly, plain English, examples over
abstractions.

Conversational rules (apply to every question):

- **One question at a time.** Never present a wall of questions.
- **Yes / no first.** Phrase questions so `yes`, `no`, `not sure`,
  or `skip` is a valid answer.
- **Choices, not blank fields.** When yes/no isn't enough, offer
  2-4 lettered options (A/B/C/D) with one-line everyday
  descriptions. Always include "Not sure — pick a sensible default".
- **Always recommend.** State which option you would pick and why
  in one sentence so the user can reply "yes" / "ok".
- **No jargon.** Avoid NFR, SLA, RBAC, PII, GDPR, throughput,
  idempotent, eventual consistency. Translate to everyday words
  with concrete examples ("Should each user only see their own
  things?" not "Is this multi-tenant?").
- **Treat `not sure` / `skip` as a default-trigger.** Apply a
  sensible default, write it into the spec marked
  "(default applied — confirm later)", and log an `RDEBT-` entry.
- **Confirm progress visibly.** After each batch, summarise what you
  captured in 2-3 plain bullets and ask "Did I get that right? (yes
  / change X)" before moving on.

Question batches (run in order, skip a batch if already answered):

1. **Goal** — problem in one sentence; how it's done today (by hand,
   spreadsheet, another tool); what success looks like in everyday
   terms.
2. **Users** — who uses it (A) just me, B) my team, C) customers /
   public, D) other); will users sign in?; do different users see
   different things?; rough headcount (A) <10, B) 10-100, C)
   100-1,000, D) >1,000, E) not sure).
3. **What it does** — main flow in plain words, step by step;
   creates / saves anything?; searches / looks things up?; shares
   with others?; deletes / undoes?; sends messages (email / SMS /
   push)?
4. **Data** — collects personal info (names, emails, phone, address,
   payments)?; special rules (medical, financial, children, EU
   users)?; deleted data: A) gone forever, B) kept for a while,
   C) not sure.
5. **Devices and access** — A) phone, B) computer, C) tablet, D) all;
   needs offline?; needs multiple languages?
6. **Speed and scale** — speed feel: A) instant, B) within a couple
   of seconds, C) a few seconds, D) longer is fine; many users at
   once? (rough peak).
7. **When things go wrong** — error handling: A) friendly error,
   try again, B) save and resume later, C) not sure; concurrent
   edits: A) last one wins, B) warn them, C) not sure; explicit
   out-of-scope items.

Mapping answers into the spec template:

| Batch | Spec sections it feeds |
|-------|------------------------|
| 1     | problem statement, Success Criteria |
| 2     | User Scenarios (As a X I want Y so that Z), actors |
| 3     | Functional Requirements, primary user journey |
| 4     | Key Entities, privacy / compliance NFRs, retention assumption |
| 5     | NFRs (devices, offline, i18n), Assumptions |
| 6     | NFRs (performance, scale), measurable Success Criteria |
| 7     | Edge Cases, Out-of-scope, conflict-resolution rules |

When `KISS_AGENT_MODE=auto` (or `--auto`), **skip the questionnaire
entirely**: apply sensible defaults, document them in the
Assumptions section, and let the business-analyst agent log
decisions to its decision log.

## Outline

The text the user typed after `/kiss.specify` in the triggering message **is** the feature description. Assume you always have it available in this conversation even if `$ARGUMENTS` appears literally below. Do not ask the user to repeat it unless they provided an empty command.

Given that feature description, do this:

1. **Generate a concise short name** (2-4 words) for the feature:
   - Analyze the feature description and extract the most meaningful keywords
   - Create a 2-4 word short name that captures the essence of the feature
   - Use action-noun format when possible (e.g., "add-user-auth", "fix-payment-bug")
   - Preserve technical terms and acronyms (OAuth2, API, JWT, etc.)
   - Keep it concise but descriptive enough to understand the feature at a glance
   - Examples:
     - "I want to add user authentication" → "user-auth"
     - "Implement OAuth2 integration for the API" → "oauth2-api-integration"
     - "Create a dashboard for analytics" → "analytics-dashboard"
     - "Fix payment processing timeout bug" → "fix-payment-timeout"

2. **Branch creation** (optional, via hook):

   If a `before_specify` hook ran successfully in the Pre-Execution Checks above, it will have created/switched to a git branch and output JSON containing `BRANCH_NAME` and `FEATURE_NUM`. Note these values for reference, but the branch name does **not** dictate the spec directory name.

   If the user explicitly provided `GIT_BRANCH_NAME`, pass it through to the hook so the branch script uses the exact value as the branch name (bypassing all prefix/suffix generation).

3. **Create the spec feature directory**:

   Specs live under the default `specs/` directory unless the user explicitly provides `KISS_FEATURE_DIRECTORY`.

   **Resolution order for `KISS_FEATURE_DIRECTORY`**:
   1. If the user explicitly provided `KISS_FEATURE_DIRECTORY` (e.g., via environment variable, argument, or configuration), use it as-is
   2. Otherwise, auto-generate it under `specs/`:
      - Check `.kiss/init-options.json` for `branch_numbering`
      - If `"timestamp"`: prefix is `YYYYMMDD-HHMMSS` (current timestamp)
      - If `"sequential"` or absent: prefix is `NNN` (next available 3-digit number after scanning existing directories in `specs/`)
      - Construct the directory name: `<prefix>-<short-name>` (e.g., `003-user-auth` or `20260319-143022-user-auth`)
      - Set `KISS_FEATURE_DIRECTORY` to `specs/<directory-name>`

   **Create the directory and spec file**:
   - `mkdir -p KISS_FEATURE_DIRECTORY`
   - Copy `templates/spec-template.md` to `KISS_FEATURE_DIRECTORY/spec.md` as the starting point
   - Set `SPEC_FILE` to `KISS_FEATURE_DIRECTORY/spec.md`
   - Persist the resolved path to `.kiss/feature.json`:

     ```json
     {
       "feature_directory": "<resolved feature dir>"
     }
     ```

     Write the actual resolved directory path value (for example, `specs/003-user-auth`), not the literal string `KISS_FEATURE_DIRECTORY`.
     This allows downstream commands (`/kiss.plan`, `/kiss.taskify`, etc.) to locate the feature directory without relying on git branch name conventions.

   **IMPORTANT**:
   - You must only create one feature per `/kiss.specify` invocation
   - The spec directory name and the git branch name are independent — they may be the same but that is the user's choice
   - The spec directory and file are always created by this command, never by the hook

4. Load `templates/spec-template.md` to understand required sections.

5. Follow this execution flow:
    1. Parse user description from arguments
       If empty: ERROR "No feature description provided"
    2. Extract key concepts from description
       Identify: actors, actions, data, constraints
    3. For unclear aspects:
       - Make informed guesses based on context and industry standards
       - Only mark with [NEEDS CLARIFICATION: specific question] if:
         - The choice significantly impacts feature scope or user experience
         - Multiple reasonable interpretations exist with different implications
         - No reasonable default exists
       - **LIMIT: Maximum 3 [NEEDS CLARIFICATION] markers total**
       - Prioritize clarifications by impact: scope > security/privacy > user experience > technical details
    4. Fill User Scenarios & Testing section
       If no clear user flow: ERROR "Cannot determine user scenarios"
    5. Generate Functional Requirements
       Each requirement must be testable
       Use reasonable defaults for unspecified details (document assumptions in Assumptions section)
    6. Define Success Criteria
       Create measurable, technology-agnostic outcomes
       Include both quantitative metrics (time, performance, volume) and qualitative measures (user satisfaction, task completion)
       Each criterion must be verifiable without implementation details
    7. Identify Key Entities (if data involved)
    8. Return: SUCCESS (spec ready for planning)

6. Write the specification to SPEC_FILE using the template structure, replacing placeholders with concrete details derived from the feature description (arguments) while preserving section order and headings.

7. **Specification Quality Validation**: After writing the initial spec, validate it against quality criteria:

   a. **Create Spec Quality Checklist**: Generate a checklist file at `KISS_FEATURE_DIRECTORY/checklists/requirements.md` using the checklist template structure with these validation items:

      ```markdown
      # Specification Quality Checklist: [FEATURE NAME]
      
      **Purpose**: Validate specification completeness and quality before proceeding to planning
      **Created**: [DATE]
      **Feature**: [Link to spec.md]
      
      ## Content Quality
      
      - [ ] No implementation details (languages, frameworks, APIs)
      - [ ] Focused on user value and business needs
      - [ ] Written for non-technical stakeholders
      - [ ] All mandatory sections completed
      
      ## Requirement Completeness
      
      - [ ] No [NEEDS CLARIFICATION] markers remain
      - [ ] Requirements are testable and unambiguous
      - [ ] Success criteria are measurable
      - [ ] Success criteria are technology-agnostic (no implementation details)
      - [ ] All acceptance scenarios are defined
      - [ ] Edge cases are identified
      - [ ] Scope is clearly bounded
      - [ ] Dependencies and assumptions identified
      
      ## Feature Readiness
      
      - [ ] All functional requirements have clear acceptance criteria
      - [ ] User scenarios cover primary flows
      - [ ] Feature meets measurable outcomes defined in Success Criteria
      - [ ] No implementation details leak into specification
      
      ## Notes
      
      - Items marked incomplete require spec updates before `/kiss.clarify-specs` or `/kiss.plan`
      ```

   b. **Run Validation Check**: Review the spec against each checklist item:
      - For each item, determine if it passes or fails
      - Document specific issues found (quote relevant spec sections)

   c. **Handle Validation Results**:

      - **If all items pass**: Mark checklist complete and proceed to step 7

      - **If items fail (excluding [NEEDS CLARIFICATION])**:
        1. List the failing items and specific issues
        2. Update the spec to address each issue
        3. Re-run validation until all items pass (max 3 iterations)
        4. If still failing after 3 iterations, document remaining issues in checklist notes and warn user

      - **If [NEEDS CLARIFICATION] markers remain**:
        1. Extract all [NEEDS CLARIFICATION: ...] markers from the spec
        2. **LIMIT CHECK**: If more than 3 markers exist, keep only the 3 most critical (by scope/security/UX impact) and make informed guesses for the rest
        3. For each clarification needed (max 3), present options to user. **In interactive mode**, phrase each question in plain everyday language for a user with no technical background, prefer yes / no, recommend a sensible default, and describe each option's effect in plain consequences (no jargon — say "users wait a bit longer" instead of "added latency"; say "rules about user data" instead of "GDPR / compliance"):

           ```markdown
           ## Question [N]: [Topic in plain words]
           
           **Where this came up**: [Quote relevant spec section]
           
           **What we need to know**: [Restate the NEEDS CLARIFICATION as a simple, everyday-language question; example: "Should users be able to undo a delete?"]
           
           **Recommended**: Option [X] — [one-sentence reason in plain words]
           
           **Your options**:
           
           | Option | Plain-language answer | What this means for you |
           |--------|------------------------|--------------------------|
           | A      | [Everyday-language answer, e.g., "Yes, keep deleted items for 30 days"] | [Plain consequence, e.g., "Users can recover mistakes; you store a bit more data"] |
           | B      | [Everyday-language answer]                                              | [Plain consequence]                                                                |
           | C      | [Everyday-language answer]                                              | [Plain consequence]                                                                |
           | Not sure | Use the recommended default                                          | [What the default is, in plain words]                                              |
           | Custom | Tell me in your own words                                              | I'll translate it into the spec for you                                            |
           
           **Reply with**: a letter (e.g., "A"), "yes" to accept the recommendation, "not sure" to use the default, or your own short answer.
           ```

        4. **CRITICAL - Table Formatting**: Ensure markdown tables are properly formatted:
           - Use consistent spacing with pipes aligned
           - Each cell should have spaces around content: `| Content |` not `|Content|`
           - Header separator must have at least 3 dashes: `|--------|`
           - Test that the table renders correctly in markdown preview
        5. Number questions sequentially (Q1, Q2, Q3 - max 3 total)
        6. Present all questions together before waiting for responses
        7. Wait for user to respond with their choices for all questions (e.g., "Q1: A, Q2: Custom - [details], Q3: B")
        8. Update the spec by replacing each [NEEDS CLARIFICATION] marker with the user's selected or provided answer
        9. Re-run validation after all clarifications are resolved

   d. **Update Checklist**: After each validation iteration, update the checklist file with current pass/fail status

8. **Report completion** to the user with:
   - `KISS_FEATURE_DIRECTORY` — the feature directory path
   - `SPEC_FILE` — the spec file path
   - Checklist results summary
   - Readiness for the next phase (`/kiss.clarify-specs` or `/kiss.plan`)

9. **Check for extension hooks**: After reporting completion, check if `.kiss/extensions.yml` exists in the project root.
   - If it exists, read it and look for entries under the `hooks.after_specify` key
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

**NOTE:** Branch creation is handled by the `before_specify` hook (git extension). Spec directory and file creation are always handled by this core command.

## Quick Guidelines

- Focus on **WHAT** users need and **WHY**.
- Avoid HOW to implement (no tech stack, APIs, code structure).
- Written for business stakeholders, not developers.
- DO NOT create any checklists that are embedded in the spec. That will be a separate command.
- In interactive mode, **the user may have no technical or
  domain background** — never present jargon, blank fields, or
  multi-question prompts. Drive the questionnaire above with
  yes / no / lettered choices / short answers and always recommend a
  default the user can accept with "yes".

### Section Requirements

- **Mandatory sections**: Must be completed for every feature
- **Optional sections**: Include only when relevant to the feature
- When a section doesn't apply, remove it entirely (don't leave as "N/A")

### For AI Generation

When creating this spec from a user prompt:

1. **Make informed guesses**: Use context, industry standards, and common patterns to fill gaps
2. **Document assumptions**: Record reasonable defaults in the Assumptions section
3. **Limit clarifications**: Maximum 3 [NEEDS CLARIFICATION] markers - use only for critical decisions that:
   - Significantly impact feature scope or user experience
   - Have multiple reasonable interpretations with different implications
   - Lack any reasonable default
4. **Prioritize clarifications**: scope > security/privacy > user experience > technical details
5. **Think like a tester**: Every vague requirement should fail the "testable and unambiguous" checklist item
6. **Common areas needing clarification** (only if no reasonable default exists):
   - Feature scope and boundaries (include/exclude specific use cases)
   - User types and permissions (if multiple conflicting interpretations possible)
   - Security/compliance requirements (when legally/financially significant)

**Examples of reasonable defaults** (don't ask about these):

- Data retention: Industry-standard practices for the domain
- Performance targets: Standard web/mobile app expectations unless specified
- Error handling: User-friendly messages with appropriate fallbacks
- Authentication method: Standard session-based or OAuth2 for web apps
- Integration patterns: Use project-appropriate patterns (REST/GraphQL for web services, function calls for libraries, CLI args for tools, etc.)

### Success Criteria Guidelines

Success criteria must be:

1. **Measurable**: Include specific metrics (time, percentage, count, rate)
2. **Technology-agnostic**: No mention of frameworks, languages, databases, or tools
3. **User-focused**: Describe outcomes from user/business perspective, not system internals
4. **Verifiable**: Can be tested/validated without knowing implementation details

**Good examples**:

- "Users can complete checkout in under 3 minutes"
- "System supports 10,000 concurrent users"
- "95% of searches return results in under 1 second"
- "Task completion rate improves by 40%"

**Bad examples** (implementation-focused):

- "API response time is under 200ms" (too technical, use "Users see results instantly")
- "Database can handle 1000 TPS" (implementation detail, use user-facing metric)
- "React components render efficiently" (framework-specific)
- "Redis cache hit rate above 80%" (technology-specific)

## Inputs

- **Feature Description** (`{context.current.feature}`): current.feature.
  - If set: Use the provided feature description as the specification subject.
  - If null: Ask the user to describe the feature they want to specify.
  - If not provided: Ask the user to provide a feature description; do not proceed without one.

## Outputs

- **Specification** (`{context.paths.specs}/{context.current.feature}/spec.md`): paths.specs}/current.feature}/spec.md.
  - Behavior: Create the spec file at this path. If the file exists and confirm_before_write is true, ask the user.
  - Overwrite guarded by `{context.preferences.confirm_before_write}`.

- **Specification Quality Checklist** (`{context.paths.specs}/{context.current.feature}/checklists/requirements.md`): paths.specs}/current.feature}/checklists/requirements.md.
  - Behavior: Create the checklist file. Overwrite if exists.
  - Overwrite guarded by `{context.preferences.confirm_before_write}`.

## Context Update

After this skill completes successfully, update `.kiss/context.yml`:

- Set current.spec to the path of the created specification file
- Set current.feature to the feature slug
- Leave all other current.* fields unchanged
- Do not modify paths.*or preferences.*

## Handoffs

- **Build Technical Plan**: run `/kiss-plan` to continue the workflow.
- **Clarify Spec Requirements**: run `/kiss-clarify-specs` to continue the workflow.
