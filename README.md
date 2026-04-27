<div align="center">
    <h1>KISS</h1>
    <h3><em>Drive Quality Together with Reusable AI Components.</em></h3>
</div>

<p align="center">
    <strong>An open-source AI delivery platform that spans the complete software development lifecycle — from requirements and architecture through implementation, testing, code review, security, and operations. Fifty-plus reusable role skills, fourteen AI-powered role agents, and native support for Agile, Waterfall, and hybrid delivery, all bootstrapped with a single command.</strong>
</p>

<p align="center">
    <a href="https://github.com/DauQuangThanh/kiss-u/releases/latest"><img src="https://img.shields.io/github/v/release/DauQuangThanh/kiss-u" alt="Latest Release"/></a>
    <a href="https://github.com/DauQuangThanh/kiss-u/stargazers"><img src="https://img.shields.io/github/stars/DauQuangThanh/kiss-u?style=social" alt="GitHub Stars"/></a>
    <a href="https://github.com/DauQuangThanh/kiss-u/blob/main/LICENSE"><img src="https://img.shields.io/github/license/DauQuangThanh/kiss-u" alt="License"/></a>
    <a href="https://dauquangthanh.github.io/kiss-u/"><img src="https://img.shields.io/badge/docs-GitHub_Pages-blue" alt="Documentation"/></a>
    <img src="https://img.shields.io/badge/skills-50%2B-brightgreen" alt="50+ Skills"/>
    <img src="https://img.shields.io/badge/role_agents-14-blue" alt="14 Role Agents"/>
    <img src="https://img.shields.io/badge/AI_providers-7-purple" alt="7 AI Providers"/>
</p>

---

## Table of Contents

- [Overview](#overview)
- [What is Spec-Driven Development?](#what-is-spec-driven-development)
- [Getting Started](#getting-started)
- [Supported AI Coding Agents](#supported-ai-coding-agents)
- [Role Agents](#role-agents)
  - [Execution Modes](#execution-modes)
  - [Artefact Layout](#artefact-layout)
- [Slash Commands](#slash-commands)
  - [Core Commands](#core-commands)
  - [Optional Commands](#optional-commands)
  - [Waterfall / Large-Project Commands](#waterfall--large-project-commands)
  - [Document Conversion Commands](#document-conversion-commands)
- [CLI Reference](#cli-reference)
- [Customization: Extensions, Presets, and Workflows](#customization-extensions-presets-and-workflows)
- [Core Philosophy](#core-philosophy)
- [Development Phases](#development-phases)
- [Prerequisites](#prerequisites)
- [Detailed Walkthrough](#detailed-walkthrough)
- [Troubleshooting](#troubleshooting)
- [Support](#support)
- [License](#license)

## Overview

KISS is a command-line installer that bootstraps projects for the full software development lifecycle. A single `kiss init` provisions fifty-plus role-specific AI skills, fourteen role-based custom agents, and a deep customization layer of extensions, presets, and workflows into your project.

The platform covers every delivery phase — requirements gathering, architecture and design, implementation, testing, code review, security review, operations, project management, and formal Waterfall deliverables — across both Agile and hybrid methodologies. It runs offline once installed, integrates with seven AI coding agents across CLI and IDE environments, and works consistently on macOS, Linux, and Windows.

<img src="./media/frwk.png" alt="KISS Logo" width="100%" height="100%"/>

## What is Spec-Driven Development?

Spec-Driven Development (SDD) is a simple idea: write down what you want to build before you build it, and keep that document at the centre of the work.

Most teams write a spec, then ignore it as soon as they start coding. SDD does the opposite. The spec is the source of truth. Your AI agent reads it to plan the work, breaks it into tasks, and writes the code to match. When something needs to change, you change the spec first.

You stay in charge of the *what* and the *why*. The agent handles most of the *how*.

## Getting Started

### 1. Install KISS

> **Important:** The only official, maintained KISS packages are published from this GitHub repository. Packages of the same name on PyPI are **not** affiliated with this project. Always install directly from GitHub.

#### Option 1: Persistent Installation (Recommended)

```bash
uv tool install kiss --from git+https://github.com/DauQuangThanh/kiss-u.git
kiss version
```

To upgrade later:

```bash
uv tool install kiss --force --from git+https://github.com/DauQuangThanh/kiss-u.git
```

See the [Upgrade Guide](./docs/upgrade.md) for full upgrade instructions.

#### Option 2: One-time Usage

```bash
uvx --from git+https://github.com/DauQuangThanh/kiss-u.git kiss init <PROJECT_NAME>
```

#### Option 3: Pre-built Wheel

Every GitHub Release ships a pre-built wheel, an sdist, and a `SHA256SUMS` file. The wheel bundles every template, preset, extension, and workflow KISS provides:

```bash
uv tool install ./kiss-<version>-py3-none-any.whl
```

Both `kiss init` and `kiss upgrade` run fully offline once the wheel is installed.

#### Option 4: Enterprise / Air-Gapped

For environments without PyPI or GitHub access, see the [Enterprise / Air-Gapped Installation guide](./docs/installation.md#enterprise--air-gapped-installation) for instructions on building portable wheel bundles from a connected machine.

#### Option 5: From Local Source

```bash
git clone https://github.com/DauQuangThanh/kiss-u.git
cd kiss
uv build
uv tool install ./dist/kiss-<version>-py3-none-any.whl
```

To rebuild and reinstall after local changes:

```bash
uv build && uv tool install --force "./dist/kiss-$(grep '^version' pyproject.toml | cut -d'"' -f2)-py3-none-any.whl"
```

### 2. Initialize a Project

Create a new project, or initialize KISS in an existing one:

```bash
# Create a new project
kiss init <PROJECT_NAME>

# Initialize in the current directory
kiss init .
kiss init --here

# Inspect project health
kiss check
```

### 3. Establish Project Principles

Launch your AI assistant in the project directory. All supported agents expose KISS commands as `/kiss-*` (skill invocation format).

Use **`/kiss-standardize`** to define the governing principles and engineering practices.

```text
/kiss-standardize Enforce TypeScript strict mode and Zod input validation on every server boundary. UI must meet WCAG AA. Database access flows through repository functions only. Use Vitest for unit tests, Playwright for end-to-end tests, and require coverage on every public function.
```

### 4. Define the Specification

Use **`/kiss-specify`** to describe the product. Concentrate on *what* and *why*, not on the technology.

```text
/kiss-specify Build Bookshelf, a single-user reading tracker. Users add books with title, author, and total page count. Each book has a status — wishlist, reading, or finished — and a progress field for the current page. When a book is finished, the user can write a short review and assign a 1-to-5 rating. Books can be tagged with custom categories. The home view shows three shelves grouped by status; tapping a book opens its detail page. No accounts; data persists locally on the device.
```

### 5. Produce a Technical Plan

Use **`/kiss-plan`** to specify the technology stack and architecture.

```text
/kiss-plan Use Next.js 14 with the App Router and TypeScript. Style with Tailwind CSS and shadcn/ui. Persist data through Prisma with SQLite stored in a local file. Read with Server Components, mutate with Server Actions, and validate every action input with Zod. No authentication.
```

### 6. Decompose into Tasks

Use **`/kiss-taskify`** to convert the implementation plan into an actionable task list.

```text
/kiss-taskify
```

### 7. Execute the Implementation

Use **`/kiss-implement`** to deliver the feature.

```text
/kiss-implement
```

## Supported AI Coding Agents

KISS integrates with seven AI coding agents across CLI and IDE environments:

Claude Code, GitHub Copilot, Cursor Agent, OpenCode, Windsurf, Gemini CLI, and Codex CLI.

For the full matrix — keys, folder layouts, and skills directories — see the [Supported AI Coding Agent Integrations guide](docs/reference/integrations.md). Run `kiss integration list` to enumerate the integrations available in your installed version.

## Role Agents

In addition to the SDD slash commands, `kiss init` installs **fourteen role-based custom agents** into your AI tool's agents directory (for example, `.claude/agents/`, `.gemini/agents/`, or `.cursor/agents/`). Each agent is an **AI authoring aid** scoped to a specific role. It delegates to a curated set of skills and writes artefacts to a known location under `docs/`.

| Agent                    | Artefacts                                                            | Delegates to (selection)                                                                                                                  |
| ------------------------ | -------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| `business-analyst`       | Spec, user stories, acceptance criteria, SRS, UAT plan, data migration plan | `kiss-specify`, `kiss-clarify-specs`, `kiss-srs`, `kiss-uat-plan`, `kiss-data-migration-plan` |
| `architect`              | Architecture intake, technology research, ADRs, C4 diagrams          | `kiss-plan`, `kiss-standardize`, `kiss-arch-intake`, `kiss-tech-research`, `kiss-adr-author`, `kiss-c4-diagrams`                           |
| `developer`              | Detailed design, API contract, data model, unit-test skeletons       | `kiss-plan`, `kiss-implement`, `kiss-standardize`, `kiss-dev-design`, `kiss-unit-tests`                                                   |
| `test-architect`         | Test strategy, framework, quality gates, RTM               | `kiss-plan`, `kiss-standardize`, `kiss-test-strategy`, `kiss-test-framework`, `kiss-quality-gates`, `kiss-traceability-matrix`          |
| `tester`                 | Test cases, execution ledger, bug reports, regression index          | `kiss-taskify`, `kiss-verify-tasks`, `kiss-test-cases`, `kiss-test-execution`, `kiss-bug-report`, `kiss-regression-tests`                 |
| `bug-fixer`              | Bug triage, fixes, regression tests, change log                      | `kiss-implement`, `kiss-verify-tasks`, `kiss-bug-triage`, `kiss-regression-tests`, `kiss-change-log`                                      |
| `code-quality-reviewer`  | Maintainability review, complexity and SOLID/DRY/KISS findings       | `kiss-standardize`, `kiss-quality-review`                                                                                                 |
| `code-security-reviewer` | OWASP Top 10 / STRIDE review, dependency audit                       | `kiss-security-review`, `kiss-dependency-audit`                                                                                           |
| `devops`                 | CI/CD, IaC, containers, observability, deployment runbook, ops handover, migration runbook | `kiss-cicd-pipeline`, `kiss-infrastructure-plan`, `kiss-containerization`, `kiss-observability-plan`, `kiss-deployment-strategy`, `kiss-handover`, `kiss-data-migration-plan` |
| `product-owner`          | Backlog, acceptance criteria, roadmap, GitHub issues                 | `kiss-tasks-to-issues`, `kiss-backlog`, `kiss-acceptance-criteria`, `kiss-roadmap`                                                         |
| `project-manager`        | Project plan, WBS, risk register, phase gates, baselines, status reports, change control | `kiss-taskify`, `kiss-feature-checklist`, `kiss-standardize`, `kiss-project-planning`, `kiss-wbs-decompose`, `kiss-phase-gate`, `kiss-baseline`, `kiss-risk-register`, `kiss-status-report`, `kiss-change-control` |
| `scrum-master`           | Sprint plan, standup log, retrospective synthesis                    | `kiss-taskify`, `kiss-feature-checklist`, `kiss-sprint-planning`, `kiss-standup`, `kiss-retrospective`                                    |
| `technical-analyst`      | Codebase scan, extracted architecture, API docs, dependency map      | `kiss-codebase-scan`, `kiss-arch-extraction`, `kiss-api-docs`, `kiss-dependency-map`                                                      |
| `ux-designer`            | Low-fidelity wireframes and Mermaid user flows                       | `kiss-wireframes`                                                                                                                         |

### Execution Modes

Every role agent supports two execution modes:

- **`interactive` (default)** — Evaluate the task, clarify scope and expectations, then execute step by step with confirmation at each decision point.
- **`auto`** — Complete the task from user input, project context, and the agent's own knowledge. Assumptions and non-trivial decisions are recorded to `docs/agent-decisions/<agent-name>/<YYYY-MM-DD>-decisions.md` using four decision kinds: `default-applied`, `alternative-picked`, `autonomous-action`, and `debt-overridden`.

Select a mode by including a keyword in the first message (`"in auto mode, ..."` or `"interactively, ..."`), or by setting `KISS_AGENT_MODE=auto` in the environment. The mode propagates to the skill layer: `auto` runs skill scripts with `--auto` / `-Auto`.

### Artefact Layout

Every role writes under a **work-type directory** rather than a per-role directory, so related artefacts cluster regardless of which agent authored them:

| Directory                       | Example Contents                                                                                                              |
| ------------------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| `docs/architecture/`            | `intake.md`, `srs.md`, `c4-context.md`, `c4-container.md`, `extracted.md`, `tech-debts.md`                                   |
| `docs/decisions/`               | `ADR-NNN-<slug>.md` (one ADR per file)                                                                                        |
| `docs/research/`                | `<topic>.md` — technology research                                                                                            |
| `docs/design/<feature>/`        | `design.md`, `api-contract.md`, `data-model.md`                                                                               |
| `docs/testing/<feature>/`       | `strategy.md`, `framework.md`, `quality-gates.md`, `test-cases.md`, `execution.md`, `test-debts.md`, `regression-index.md`           |
| `docs/analysis/`                | `codebase-scan.md`, `api-docs.md`, `dependencies.md`, `traceability-matrix.md`, `srs.md`, `uat-plan/<feature>/uat-plan.md`, `data-migration-plan.md`, `field-mapping.md` |
| `docs/bugs/`                    | `BUG-NNN-<slug>.md`, `triage.md`, `change-register.md`, `fix-debts.md`                                                        |
| `docs/reviews/<feature>/`       | `quality.md`, `security.md`, `dependencies.md`, plus shared `docs/reviews/{quality,security}-debts.md`                       |
| `docs/operations/`              | `cicd.md`, `infra.md`, `containers.md`, `monitoring.md`, `deployment.md`, `migration-runbook.md`, `handover/`  |
| `docs/product/`                 | `backlog.md`, `acceptance.md`, `roadmap.md`                                                                                   |
| `docs/project/`                 | `project-plan.md`, `wbs-index.md`, `risk-register.md`, `status-YYYY-MM-DD.md`, `change-log.md`, `gates/`, `pm-debts.md`      |
| `docs/baselines/<label>/`       | `manifest.md`, `artefacts/` (frozen copies with SHA-256 hashes)                                                              |
| `docs/agile/`                   | `sprint-NN-plan.md`, `standups/YYYY-MM-DD.md`, `retro-sprint-NN.md`                                                           |
| `docs/ux/<feature>/`            | `wireframes.md`, `user-flows.md`                                                                                              |
| `docs/agent-decisions/<agent>/` | Per-run decision log (auto mode)                                                                                              |

All paths resolve through `.kiss/context.yml`. Adjust `paths.docs` if your project stores documentation outside `docs/`.

### Scope: AI Authoring Only

Role agents are **authoring aids**, not meeting facilitators or stakeholder proxies. They draft artefacts, solicit input from the user at the keyboard, and honour `preferences.confirm_before_write`.

They do **not** facilitate standups, sprint planning, or retrospectives; interview stakeholders or end users; convene change-control boards; negotiate with vendors; approve or sign off on decisions; or communicate with third parties through any channel. Each agent's prompt enumerates its `does` and `does not` lists explicitly.

## Slash Commands

After `kiss init`, your AI coding agent gains access to the slash commands listed below. All supported agents use the `/kiss-*` invocation format.

### Core Commands

Essential for the Spec-Driven Development workflow:

| Command                  | Agent Skill            | Description                                                                |
| ------------------------ | ---------------------- | -------------------------------------------------------------------------- |
| `/kiss-standardize`      | `kiss-standardize`     | Create or update governing principles and development guidelines.          |
| `/kiss-specify`          | `kiss-specify`         | Define what to build — requirements and user stories.                      |
| `/kiss-plan`             | `kiss-plan`            | Produce a technical implementation plan with the chosen stack.             |
| `/kiss-taskify`          | `kiss-taskify`         | Generate an actionable task list for implementation.                       |
| `/kiss-tasks-to-issues`  | `kiss-tasks-to-issues` | Convert generated tasks into GitHub issues for tracking and execution.     |
| `/kiss-implement`        | `kiss-implement`       | Execute the task list and build the feature according to the plan.        |

### Optional Commands

For enhanced quality and validation:

| Command                 | Agent Skill             | Description                                                                                                |
| ----------------------- | ----------------------- | ---------------------------------------------------------------------------------------------------------- |
| `/kiss-clarify-specs`   | `kiss-clarify-specs`    | Resolve underspecified areas. Recommended before `/kiss-plan`.                                             |
| `/kiss-verify-tasks`    | `kiss-verify-tasks`     | Cross-artefact consistency and coverage analysis. Run after `/kiss-taskify` and before `/kiss-implement`.  |
| `/kiss.checklist`       | `kiss-checklist`        | Generate quality checklists that validate requirements completeness, clarity, and consistency.             |

### Waterfall / Large-Project Commands

Additional skills for formal delivery lifecycles — Waterfall, government contracts, regulated industries, and any project that requires phase gates, traceability, or formal hand-overs.

| Command                        | Agent Skill                   | Description                                                                                                     |
| ------------------------------ | ----------------------------- | --------------------------------------------------------------------------------------------------------------- |
| `/kiss-srs`                    | `kiss-srs`                    | Aggregate all feature specs into an IEEE 29148:2018-aligned Software Requirements Specification (SRS).          |
| `/kiss-traceability-matrix`    | `kiss-traceability-matrix`    | Build a Requirements Traceability Matrix (RTM) linking FR/NFR → design → tasks → tests → bugs.                 |
| `/kiss-phase-gate`             | `kiss-phase-gate`             | Author a Waterfall phase-exit checklist and sign-off record (SRR, CDR, TRR, ORR, go-live).                     |
| `/kiss-wbs-decompose`          | `kiss-wbs-decompose`          | Decompose the project-plan WBS into feature stub directories, bridging planning and specification.              |
| `/kiss-baseline`               | `kiss-baseline`               | Snapshot artefacts as a named, immutable baseline with SHA-256 manifest and optional git tag.                   |
| `/kiss-uat-plan`               | `kiss-uat-plan`               | Draft a business-workflow-level UAT plan with scenarios, entry/exit criteria, and a sponsor sign-off ledger.    |
| `/kiss-handover`               | `kiss-handover`               | Draft the operations/support hand-over package — runbook index, L1/L2/L3 escalation matrix, training plan.     |
| `/kiss-data-migration-plan`    | `kiss-data-migration-plan`    | Draft a data migration plan covering strategy, field mapping, ETL outline, cutover window, and rollback.        |

### Document Conversion Commands

Round-trip translation between Office formats and Markdown for version-control-friendly editing:

| Command              | Agent Skill          | Description                                                                                          |
| -------------------- | -------------------- | ---------------------------------------------------------------------------------------------------- |
| `/kiss-docx-markdown` | `kiss-docx-markdown` | Convert `.docx` ↔ Markdown with high-fidelity round-trip via pandoc + sidecar metadata.             |
| `/kiss-pptx-markdown` | `kiss-pptx-markdown` | Convert `.pptx` ↔ Markdown preserving slide structure, notes, layouts, and images.                  |
| `/kiss-xlsx-markdown` | `kiss-xlsx-markdown` | Convert `.xlsx` ↔ Markdown preserving sheets, formulas, named ranges, and formatting via sidecar.   |

## CLI Reference

For complete command details, options, and examples, see the [CLI Reference](docs/reference/overview.md).

## Customization: Extensions, Presets, and Workflows

KISS can be tailored through three complementary mechanisms — **extensions**, **presets**, and **workflows** — plus project-local overrides for one-off adjustments.

| Priority | Component   | Purpose                                              | Location                                         |
| -------: | ----------- | ---------------------------------------------------- | ------------------------------------------------ |
|        1 | Presets     | Customize the format of core and extension artefacts | `.kiss/presets/<name>/`                          |
|        2 | Extensions  | Add new capabilities                                 | `.kiss/extensions/<name>/`                       |
|        3 | KISS Core   | Built-in SDD skills                                  | `<agent-config>/skills/<kiss-name>/` (per-skill) |

Workflows orchestrate multi-step sequences across these layers and are resolved independently from the catalog.

- **Skills are self-contained.** Each installed skill is a folder bundling its `SKILL.md` (or `.md` / `.toml` for flat-file agents) with the scripts and templates it requires. For example, `/kiss-specify` installs to `.claude/skills/kiss-specify/` alongside `scripts/bash/create-new-feature.sh` and `templates/spec-template.md`. There is no shared `.kiss/scripts/` or `.kiss/templates/` directory.
- **Extension and preset commands** are applied at **install time**. When you run `kiss extension add` or `kiss preset add`, command files are written into the agent directory and overrides take effect immediately.
- When multiple presets or extensions provide the same command, the highest-priority version wins. On removal, the next-highest-priority version is restored automatically.

### Extensions — Add New Capabilities

Use **extensions** to introduce functionality beyond the KISS core: domain-specific commands, external tool integrations, additional development phases, or quality gates.

Typical extensions include Jira/Linear ticket sync, post-implementation code review, V-Model test traceability, project health diagnostics, and Git feature-branch automation (the bundled `git` extension).

```bash
# Browse the catalog
kiss extension search
kiss extension search --tag workflow
kiss extension info <name>

# Install (requires a project initialized with `kiss init`)
kiss extension add <name>
kiss extension add <name> --dev --from ./path/to/extension
kiss extension add <name> --from https://example.com/my-extension.zip

# Manage installed extensions
kiss extension list
kiss extension update <name>
kiss extension disable <name>
kiss extension set-priority <name> 5
kiss extension remove <name>
```

After installation, commands appear in the agent's directory (for example, `.claude/skills/` or `.github/prompts/`) and are invoked as `/kiss.<ext>.<command>`.

#### Configure

Most extensions ship with a configuration template:

```bash
cp .kiss/extensions/<name>/<name>-config.template.yml \
   .kiss/extensions/<name>/<name>-config.yml
```

Configuration merge order (later wins): extension defaults → `<name>-config.yml` → `<name>-config.local.yml` → `KISS_<NAME>_*` environment variables.

#### Custom Catalogs

```bash
kiss extension catalog list
kiss extension catalog add https://example.com/catalog.json \
  --name my-org --priority 5 --install-allowed
kiss extension catalog remove my-org
```

Catalogs stack by priority — lower numbers take precedence. Override every catalog in CI by exporting `KISS_CATALOG_URL=https://.../catalog.json`.

See the [Extensions reference](docs/reference/extensions.md) and the [Extension User Guide](extensions/EXTENSION-USER-GUIDE.md) for end-to-end workflows.

### Presets — Customize Existing Workflows

Use **presets** to change *how* KISS operates without adding new capabilities. Presets override the templates and commands shipped with the core *and* with installed extensions — for example, enforcing a compliance-oriented spec format, applying domain-specific terminology, or aligning artefacts with organizational standards.

```bash
kiss preset search
kiss preset add <preset_id>
kiss preset list
kiss preset resolve <name>     # trace which file wins resolution
kiss preset set-priority <preset_id> 5
```

Common preset use cases include restructuring spec templates for regulatory traceability, adapting the workflow to a methodology (Agile, Kanban, Waterfall, jobs-to-be-done, domain-driven design), adding mandatory security-review gates, enforcing test-first task ordering, and localizing artefacts into a different language.

See the [Presets reference](docs/reference/presets.md) for resolution order and priority stacking.

### Workflows — Orchestrate Multi-Step Sequences

**Workflows** chain commands, prompts, shell steps, and human checkpoints into repeatable sequences. They support conditional logic, loops, fan-out/fan-in, and pause/resume from the exact step where execution stopped.

```bash
# Discover and install
kiss workflow search
kiss workflow add <source>
kiss workflow list

# Run, with declared inputs supplied via -i key=value
kiss workflow run kiss \
  -i spec="Build Bookshelf, a single-user reading tracker" \
  -i scope=full

# Resume after a gate, manual checkpoint, or fix
kiss workflow resume <run_id>
kiss workflow status <run_id>
```

See the [Workflows reference](docs/reference/workflows.md) for the full command surface.

### Choosing Between Mechanisms

| Goal                                              | Choose     |
| ------------------------------------------------- | ---------- |
| Add a new command or capability                   | Extension  |
| Customize the format of specs, plans, or tasks    | Preset     |
| Integrate an external tool or service             | Extension  |
| Enforce organizational or regulatory standards    | Preset     |
| Automate a multi-step, multi-checkpoint sequence  | Workflow   |
| Ship reusable domain-specific templates           | Preset (for overrides) or Extension (when bundled with new commands) |

## Core Philosophy

Spec-Driven Development is a structured process that emphasizes:

- **Intent-driven development**, where specifications define the "*what*" before the "*how*".
- **Rich specification creation** guided by guardrails and organizational principles.
- **Multi-step refinement** in place of one-shot code generation from prompts.
- **Deep use of advanced AI capabilities** for specification interpretation and synthesis.

## Development Phases

| Phase                                     | Focus                     | Key Activities                                                                                                                                                      |
| ----------------------------------------- | ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **0-to-1 Development** ("Greenfield")     | Generate from scratch     | <ul><li>Start from high-level requirements</li><li>Generate specifications</li><li>Plan implementation steps</li><li>Build production-ready applications</li></ul> |
| **Creative Exploration**                  | Parallel implementations  | <ul><li>Explore diverse solutions</li><li>Support multiple technology stacks and architectures</li><li>Experiment with UX patterns</li></ul>                       |
| **Iterative Enhancement** ("Brownfield")  | Brownfield modernization  | <ul><li>Add features iteratively</li><li>Modernize legacy systems</li><li>Adapt processes over time</li></ul>                                                      |

## Prerequisites

- Linux, macOS, or Windows.
- A [supported](#supported-ai-coding-agents) AI coding agent.
- [uv](https://docs.astral.sh/uv/) for package management.
- [Python 3.11+](https://www.python.org/downloads/).
- [Git](https://git-scm.com/downloads).

If you encounter issues with a specific agent, please open an issue so the integration can be refined.

## Detailed Walkthrough

<details>
<summary>Step-by-step implementation guide</summary>

The example below builds **Bookshelf**, a single-user reading tracker, from a blank repository.

### Step 0: Bootstrap

```bash
# Create a new project, with interactive multi-select for integrations
kiss init bookshelf

# Or initialize KISS in the current repository
kiss init .
kiss init --here --force      # merge into a non-empty directory

# Specify integrations non-interactively
kiss init bookshelf --integration claude --integration copilot

# Use the generic integration for an unlisted agent
kiss init bookshelf --integration generic --integration-options="--commands-dir .myagent/commands"

# Skip CLI tool checks
kiss init bookshelf --integration claude --ignore-agent-tools
```

![KISS bootstrapping a new project in the terminal](./media/frwk.png)

### Step 1: Establish Project Principles

Launch your AI agent (for example, `claude`) inside the project directory.

![Bootstrapping the Claude Code environment](./media/bootstrap-claude-code.gif)

Setup is correct when `/kiss-standardize`, `/kiss-specify`, `/kiss-plan`, `/kiss-taskify`, and `/kiss-implement` are listed.

```text
/kiss-standardize Establish principles for Bookshelf. Enforce TypeScript strict mode and Zod validation on every server boundary. UI must meet WCAG AA. Database access flows through repository functions only. Tests run with Vitest (unit) and Playwright (end-to-end), and every public function requires test coverage.
```

This creates or updates `docs/standards.md`, which subsequent commands consult.

### Step 2: Create the Specification

> [!IMPORTANT]
> Be explicit about *what* you are building and *why*. **Do not focus on the technology stack at this stage.**

```text
/kiss-specify Build Bookshelf, a single-user reading tracker. A user adds books with title, author, and total page count. Each book has a status — wishlist, reading, or finished — and a current-page field. When a book is finished, the user can write a short review and assign a 1-to-5 rating. Books can be tagged with custom categories. The home view shows three shelves grouped by status; tapping a book opens its detail page. No accounts; data persists locally.
```

After the prompt is submitted, the agent begins planning, drafts a specification, and triggers built-in scripts that prepare the repository. On completion, a feature branch is created (for example, `001-bookshelf`) with a specification under `specs/001-bookshelf/spec.md`.

Project layout at this stage:

```text
├── .claude
│   └── skills
│       ├── kiss-specify
│       │   ├── SKILL.md
│       │   ├── scripts/bash/{create-new-feature,common}.sh
│       │   ├── scripts/powershell/{create-new-feature,common}.ps1
│       │   └── templates/spec-template.md
│       ├── kiss-plan
│       │   ├── SKILL.md
│       │   ├── scripts/bash/{setup-plan,common}.sh
│       │   ├── scripts/powershell/{setup-plan,common}.ps1
│       │   └── templates/plan-template.md
│       ├── kiss-standardize/…
│       └── kiss-{taskify,verify-tasks,clarify-specs,checklist,implement,tasks-to-issues}/…
├── .kiss
│   ├── context.yml
│   ├── integration.json
│   └── manifest.json
└── docs
    ├── standards.md
    └── specs
        └── 001-bookshelf
            └── spec.md
```

### Step 3: Clarify the Specification

Run the structured clarification workflow **before** producing a technical plan to minimize rework.

```text
/kiss.clarify-specs Focus on the rules around progress tracking and the review/rating flow.
```

Optionally follow with ad-hoc refinement:

```text
The progress field accepts values from 0 to the book's total pages. When progress equals the total, prompt the user to mark the book as finished. Reviews accept up to 1,000 characters and may be edited until a book is moved back to "reading".
```

Validate the **Review & Acceptance Checklist**:

```text
Read the review and acceptance checklist and check off each item if the spec satisfies the criterion.
```

If the project is exploratory (a spike or prototype), state that explicitly so the agent does not block on missing clarifications.

### Step 4: Generate the Plan

```text
/kiss-plan Use Next.js 14 with the App Router and TypeScript. Style with Tailwind CSS and shadcn/ui. Persist data through Prisma against a local SQLite file. Read with Server Components, mutate with Server Actions, and validate every action input with Zod. No authentication.
```

Output:

```text
.
├── CLAUDE.md
├── .claude/skills/…
├── .kiss/
│   ├── context.yml
│   ├── integration.json
│   └── manifest.json
└── docs
    ├── standards.md
    └── specs
        └── 001-bookshelf
            ├── contracts
            │   └── api-spec.json
            ├── data-model.md
            ├── plan.md
            ├── quickstart.md
            ├── research.md
            └── spec.md
```

Inspect `research.md` to confirm the chosen stack matches your intent. Ask the agent to refine specifics — for example, the Prisma schema or the Server Actions contract — and to verify the locally installed Node.js version.

For rapidly evolving libraries, request targeted parallel research:

```text
Identify which decisions in plan.md depend on Next.js 14 App Router behaviour that has changed recently. For each, spawn a focused research task. Update research.md with version-specific findings.
```

> [!NOTE]
> The agent may add components that were not requested. Ask for the rationale and source of any such additions.

### Step 5: Validate the Plan

```text
Audit plan.md and the implementation-detail files. For each task, verify that the relevant data-model, contract, and research notes are referenced so a developer can follow the steps without ambiguity.
```

Run the checklist a second time before implementation begins. If the [GitHub CLI](https://docs.github.com/en/github-cli/github-cli) is installed, the agent can also open a pull request from the feature branch to `main` with a detailed description for review.

> [!NOTE]
> Before implementation, ask the agent to flag over-engineered components. The plan must adhere to the [standards](docs/standards.md) as the foundation for every decision.

### Step 6: Generate the Task Breakdown

```text
/kiss-taskify
```

This creates `tasks.md` in the feature directory, containing:

- **Task breakdown organized by user story.** Each user story becomes a separate implementation phase.
- **Dependency management.** Tasks are ordered to respect dependencies (for example, Prisma schema before repository functions, repository functions before Server Actions).
- **Parallel execution markers.** Tasks eligible for parallel execution are marked with `[P]`.
- **File-path specifications.** Each task lists the exact paths where implementation should occur.
- **Test-driven structure.** Test tasks precede their corresponding implementation tasks.
- **Checkpoint validation.** Each user-story phase ends with a checkpoint that validates independent functionality.

### Step 7: Implement

```text
/kiss-implement
```

`/kiss-implement` will:

- Validate that all prerequisites are present (standards, spec, plan, and tasks).
- Parse the task breakdown from `tasks.md`.
- Execute tasks in the correct order, respecting dependencies and parallel markers.
- Follow the TDD approach defined in the task plan.
- Report progress and handle errors.

> [!IMPORTANT]
> The AI agent executes local CLI commands (for example, `npm`, `npx prisma`, `npm test`). Ensure the required tools are installed.

After implementation completes, run the application and resolve any runtime errors not surfaced in CLI logs (for example, browser console errors). Paste such errors back to the agent for resolution.

</details>

---

## Troubleshooting

### Git Credential Manager on Linux

If Git authentication fails on Linux, install the Git Credential Manager:

```bash
#!/usr/bin/env bash
set -e
echo "Downloading Git Credential Manager v2.6.1..."
wget https://github.com/git-ecosystem/git-credential-manager/releases/download/v2.6.1/gcm-linux_amd64.2.6.1.deb
echo "Installing Git Credential Manager..."
sudo dpkg -i gcm-linux_amd64.2.6.1.deb
echo "Configuring Git to use GCM..."
git config --global credential.helper manager
echo "Cleaning up..."
rm gcm-linux_amd64.2.6.1.deb
```

## Support

To report issues, request features, or ask questions about Spec-Driven Development, please open a [GitHub issue](https://github.com/DauQuangThanh/kiss-u/issues/new).

## License

KISS is released under the MIT License. See the [LICENSE](./LICENSE) file for full terms.
