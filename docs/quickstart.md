# Quick Start Guide

This guide walks through Spec-Driven Development with KISS using a single example project: **Bookshelf**, a single-user reading tracker.

> [!NOTE]
> Every installed skill folder ships both Bash (`.sh`) and PowerShell (`.ps1`) script variants. KISS auto-selects the right one for the host OS at install time — no flag required.

## The Six-Step Process

> [!TIP]
> **Context awareness.** KISS commands detect the active feature from the current Git branch (for example, `001-bookshelf`). Switch features by switching branches.

### Step 1: Initialize a Project

In the terminal:

```bash
# Create a new project with an interactive integration multi-select
uvx --from git+https://github.com/DauQuangThanh/kiss-u.git kiss init bookshelf

# Or initialize KISS in the current directory
uvx --from git+https://github.com/DauQuangThanh/kiss-u.git kiss init .
```

Specify an integration directly to skip the multi-select:

```bash
uvx --from git+https://github.com/DauQuangThanh/kiss-u.git kiss init bookshelf --integration claude
```

### Step 2: Establish Standards

In the AI agent's chat interface, use `/kiss-standardize` to define governing principles:

```markdown
/kiss-standardize Enforce TypeScript strict mode and Zod validation on every server boundary. UI must meet WCAG AA. Database access flows through repository functions only. Use Vitest for unit tests and Playwright for end-to-end tests; require coverage on every public function.
```

### Step 3: Create the Specification

Use `/kiss-specify` to describe what you are building. Focus on the **what** and **why**, not the technology.

```markdown
/kiss-specify Build Bookshelf, a single-user reading tracker. Users add books with title, author, and total page count. Each book has a status — wishlist, reading, or finished — and a current-page field. When a book is finished, the user can write a short review and assign a 1-to-5 rating. Books can be tagged with custom categories. The home view shows three shelves grouped by status; tapping a book opens its detail page. No accounts; data persists locally.
```

### Step 4: Refine the Specification

Use `/kiss-clarify-specs` to resolve ambiguities. Provide focus areas as arguments:

```markdown
/kiss-clarify-specs Focus on the rules around progress tracking and the review/rating flow.
```

### Step 5: Produce a Technical Plan

Use `/kiss-plan` to specify the technology stack and architecture:

```markdown
/kiss-plan Use Next.js 14 with the App Router and TypeScript. Style with Tailwind CSS and shadcn/ui. Persist data through Prisma against a local SQLite file. Read with Server Components and mutate with Server Actions, validating each action input with Zod. No authentication.
```

### Step 6: Decompose and Implement

Generate the task list:

```markdown
/kiss-taskify
```

Optionally validate cross-artefact consistency:

```markdown
/kiss-verify-tasks
```

Execute the plan:

```markdown
/kiss-implement
```

> [!TIP]
> **Phased implementation.** For larger projects, implement in phases (for example: Phase 1 — schema and shelves, Phase 2 — book detail and progress, Phase 3 — reviews and tagging). This avoids context saturation and allows validation between stages.

## Detailed Example: Building Bookshelf

The example below expands on the six-step process.

### Step 1: Define Standards

```markdown
/kiss-standardize Establish principles for Bookshelf. Enforce TypeScript strict mode and Zod validation on every server boundary. UI must meet WCAG AA. Database access flows through repository functions only. Tests run with Vitest (unit) and Playwright (end-to-end), and every public function requires test coverage.
```

### Step 2: Define Requirements

```markdown
/kiss-specify Build Bookshelf, a single-user reading tracker. A user adds books with title, author, and total page count. Each book has a status — wishlist, reading, or finished — and a current-page field. When a book is finished, the user can write a short review and assign a 1-to-5 rating. Books can be tagged with custom categories. The home view shows three shelves grouped by status; tapping a book opens its detail page. No accounts; data persists locally on the device.
```

### Step 3: Refine the Specification

```markdown
/kiss-clarify-specs The progress field accepts values from 0 to the book's total pages. When progress reaches the total, prompt the user to mark the book as finished. Reviews accept up to 1,000 characters and may be edited until the book moves back to "reading".
```

Continue refining as needed:

```markdown
/kiss-clarify-specs Categories are user-defined free-text tags, normalized to lowercase. A book may have any number of categories. Selecting a category from the home view filters the visible shelves to books carrying that tag.
```

### Step 4: Validate the Specification

```markdown
/kiss-feature-checklist
```

### Step 5: Generate the Technical Plan

```markdown
/kiss-plan Use Next.js 14 with the App Router and TypeScript. Style with Tailwind CSS and shadcn/ui. Persist data through Prisma against a local SQLite file. Read with Server Components, mutate with Server Actions, and validate every action input with Zod. No authentication.
```

### Step 6: Generate the Task List

```markdown
/kiss-taskify
```

### Step 7: Validate and Implement

Audit the implementation plan:

```markdown
/kiss-verify-tasks
```

Execute the plan:

```markdown
/kiss-implement
```

> [!TIP]
> **Phased implementation.** For Bookshelf, a sensible split is: Phase 1 — Prisma schema, repository functions, and the shelves view; Phase 2 — book detail and progress tracking; Phase 3 — reviews, ratings, and category filtering.

## Key Principles

- **Be explicit** about what you are building and why.
- **Avoid the technology stack** during specification.
- **Iterate** on specifications before producing a plan.
- **Validate** the plan before implementation.
- **Delegate** implementation details to the agent.

## Beyond Slash Commands: Role Agents

In addition to `/kiss-*` slash commands, `kiss init` installs **fourteen role-based custom agents** into the agent's directory (for example, `.claude/agents/`, `.cursor/agents/`, `.gemini/agents/`):

`business-analyst`, `architect`, `developer`, `test-architect`, `tester`, `bug-fixer`, `code-quality-reviewer`, `code-security-reviewer`, `devops`, `product-owner`, `project-manager`, `scrum-master`, `technical-analyst`, `ux-designer`.

Each agent is an **AI authoring aid** — it drafts artefacts from your input and from upstream artefacts produced by other agents. Role agents do not facilitate meetings, interview stakeholders, approve changes, or communicate with third parties.

### Execution Modes

Every agent supports two modes:

- **`interactive` (default)** — the agent clarifies the task, then executes step by step, pausing for confirmation at decision points.
- **`auto`** — the agent completes the task using your input, project context, and its own knowledge. Assumptions and non-trivial decisions are written to `docs/agent-decisions/<agent-name>/<YYYY-MM-DD>-decisions.md`.

Select a mode via a keyword in your first message (`"in auto mode, ..."` / `"interactively, ..."`) or by setting `KISS_AGENT_MODE=auto` in the environment.

### Where Outputs Land

Role-agent artefacts are written under `docs/<work-type>/`, not per role:

- `docs/architecture/` · `docs/decisions/` · `docs/research/`
- `docs/design/<feature>/` · `docs/testing/<feature>/`
- `docs/bugs/` · `docs/reviews/<feature>/`
- `docs/operations/` · `docs/product/` · `docs/project/`
- `docs/agile/` · `docs/analysis/` · `docs/ux/<feature>/`
- `docs/agent-decisions/<agent>/` (auto-mode decision logs)

See the [Role Agents section of the README](../README.md#role-agents) for the full agent-to-skills map.

## Next Steps

- Read the [complete methodology](https://github.com/DauQuangThanh/kiss-u/blob/main/spec-driven.md) for in-depth guidance.
- Browse the [source on GitHub](https://github.com/DauQuangThanh/kiss-u).
- Explore [extensions](reference/extensions.md), [presets](reference/presets.md), and [workflows](reference/workflows.md) to extend KISS.

## Waterfall and Large-Project Workflows

For formal delivery lifecycles — government contracts, regulated industries, or any project requiring phase gates and formal sign-offs — KISS provides an additional set of commands on top of the core SDD flow:

| Stage | Commands |
|---|---|
| Requirements formalisation | `/kiss-srs` (IEEE 29148:2018 SRS), `/kiss-wbs-decompose` (WBS → feature stubs) |
| Traceability | `/kiss-traceability-matrix` (FR/NFR → design → tasks → tests → bugs) |
| Phase gates | `/kiss-phase-gate` (SRR, CDR, TRR, ORR, go-live checklists) |
| Baselines | `/kiss-baseline` (immutable snapshot with SHA-256 manifest + git tag) |
| Testing | `/kiss-uat-plan` (business UAT plan with sponsor sign-off) |
| Go-live | `/kiss-handover` (runbook index, L1/L2/L3 escalation, training), `/kiss-data-migration-plan` (migration strategy, field mapping, cutover runbook) |

A typical Waterfall sequence on top of the six-step SDD flow:

```text
/kiss-srs                   → produce SRS from all feature specs
/kiss-phase-gate requirements → SRR gate: confirm SRS is complete
/kiss-traceability-matrix   → build RTM before coding starts
/kiss-phase-gate architecture → CDR gate: confirm design is approved
/kiss-baseline design       → freeze the design baseline
/kiss-uat-plan              → draft UAT plan while development is underway
/kiss-phase-gate ttr        → TRR gate: confirm test readiness
/kiss-data-migration-plan   → plan data migration (if applicable)
/kiss-phase-gate orr        → ORR gate: confirm ops readiness
/kiss-handover              → produce hand-over package
/kiss-baseline release      → freeze the release baseline
/kiss-phase-gate go-live    → final gate before go-live
```
