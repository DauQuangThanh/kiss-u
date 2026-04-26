# Feature Specification: workflow-engine

**Feature Slug**: `workflow-engine`
**Created**: 2026-04-26
**Status**: Draft (reverse-engineered)
**Mode**: auto
**Input**: `cli/workflow.py:79-592`,
`workflows/engine.py:1-778`,
`workflows/__init__.py:1-65`,
`workflows/steps/*` (10 step types),
`docs/architecture/extracted.md` §3.

## Problem Statement

A developer running an SDD workflow often has multi-step
sequences that combine AI-CLI invocations, shell commands,
prompts, and conditional branches — for example "scaffold
spec → clarify → plan → taskify → implement → review". Hand-
running each step is slow, error-prone, and inconsistent across
team members.

`kiss workflow` provides a declarative YAML-based workflow
engine with 10 built-in step types so a workflow can be defined
once, version-controlled, and replayed deterministically by any
team member. Workflows can be:

- run from a registered id or directly from a YAML file path;
- resumed from a partial-state file after a crash or pause;
- inspected for status mid-run;
- shared via catalogs.

Source evidence: `src/kiss_cli/cli/workflow.py:79-592` (12
workflow commands); `src/kiss_cli/workflows/engine.py:1-778`
(`WorkflowEngine`, `WorkflowDefinition`);
`src/kiss_cli/workflows/__init__.py:43-65` (`STEP_REGISTRY` lists
the 10 step types: `command`, `do-while`, `fan-in`, `fan-out`,
`gate`, `if`, `prompt`, `shell`, `switch`, `while`);
`workflows/steps/` (per-step implementations).

## User Scenarios & Testing

### User Story 1 — Run a registered workflow (Priority: P1)

As a developer wanting to drive an SDD pipeline, I want to run
`kiss workflow run kiss` (the bundled workflow id) and have
kiss execute every step end-to-end, displaying live progress.

**Why this priority**: Headline value of the engine — without
`run`, the rest of the engine has no surface.

**Independent test**: Run `kiss workflow run kiss` against a
seeded fixture; confirm the engine progresses through each step
and exits with code `0` on success.

**Acceptance Scenarios**:

1. **Given** a registered workflow id exists, **When** the
   user runs `kiss workflow run <id>`, **Then** the engine
   loads the workflow via
   `WorkflowEngine.load_workflow` and executes every step
   (`cli/workflow.py:95-162`).
2. **Given** the user supplies a YAML file path instead of an
   id, **When** the command runs, **Then** the engine loads
   from the path (`cli/workflow.py:97`).
3. **Given** the source path / id does not exist, **When** the
   command runs, **Then** the command exits with code `1` and
   prints the `FileNotFoundError` / `ValueError` message
   (`cli/workflow.py:114-119`).

### User Story 2 — Pass parameters to a workflow run (Priority: P1)

As a developer who wants to parametrise a workflow, I want to
pass `-i key=value` so the engine substitutes the values into
expressions / step inputs.

**Acceptance Scenarios**:

1. **Given** the user runs
   `kiss workflow run <id> -i feature=user-auth -i priority=high`,
   **When** the command runs, **Then** the values are bound
   into the workflow's variable scope and accessible via the
   expression evaluator (`workflows/expressions.py`).

### User Story 3 — Resume a paused or crashed workflow (Priority: P1)

As a developer whose workflow stopped at a `gate` step (waiting
for human approval) or whose workflow run crashed, I want to
resume it without re-running already-completed steps.

**Acceptance Scenarios**:

1. **Given** a workflow ran partially and persisted its state,
   **When** the user runs `kiss workflow resume`, **Then** the
   engine reloads the state and continues from the last
   incomplete step (`cli/workflow.py:164-198`).

### User Story 4 — Inspect status of a running / paused workflow (Priority: P1)

**Acceptance Scenarios**:

1. **Given** a workflow is running or paused, **When** the
   user runs `kiss workflow status`, **Then** the command
   prints the current step, completed steps, and any pending
   gate (`cli/workflow.py:199-261`).

### User Story 5 — Add / remove / list / search / inspect workflows (Priority: P2)

As a developer managing the team's workflow catalog, I want to:

- `kiss workflow add <id-or-path>` — register a new workflow;
- `kiss workflow remove <id>` — drop one;
- `kiss workflow list` — show installed;
- `kiss workflow search <q>` — search the catalog;
- `kiss workflow info <id>` — inspect metadata.

**Acceptance Scenarios**:

1. **Given** a YAML file or registered id, **When** the user
   runs `kiss workflow add <src>`, **Then** the workflow is
   registered (`cli/workflow.py:290-390`).
2. **Given** an installed workflow, **When** the user runs
   `kiss workflow remove <id>`, **Then** it is dropped
   (`cli/workflow.py:391-418`).
3. **Given** any kiss project, **When** the user runs
   `kiss workflow list`, **Then** the command prints a Rich
   table of installed workflows (`cli/workflow.py:262-289`).
4. **Given** the user runs `kiss workflow search <q>`,
   **When** the command runs, **Then** matching catalog
   entries are returned (`cli/workflow.py:419-453`).
5. **Given** a known workflow, **When** the user runs
   `kiss workflow info <id>`, **Then** the command prints
   metadata (`cli/workflow.py:454-525`).

### User Story 6 — Manage the catalog (Priority: P3)

**Acceptance Scenarios**:

1. **Given** a valid catalog source, **When** the user runs
   `kiss workflow catalog add <name> <src>`, **Then** the
   catalog is registered (`cli/workflow.py:549-571`).
2. **Given** an existing catalog, **When** the user runs
   `kiss workflow catalog remove <name>`, **Then** the
   catalog is deregistered (`cli/workflow.py:572-592`).
3. **Given** any kiss project, **When** the user runs
   `kiss workflow catalog list`, **Then** the command prints
   every registered catalog (`cli/workflow.py:526-548`).

### User Story 7 — Compose with the 10 built-in step types (Priority: P2)

As a workflow author, I want to use any of the 10 built-in
step types — `command`, `shell`, `prompt`, `gate`, `if`,
`switch`, `while`, `do-while`, `fan-out`, `fan-in` — to
express my workflow declaratively.

**Acceptance Scenarios**:

1. **Given** a workflow YAML using `command:` step, **When**
   the engine runs that step, **Then** kiss invokes the
   target slash command via the active integration's
   `dispatch_command` (`integrations/base.py:147-225`).
2. **Given** a `shell:` step, **When** the engine runs it,
   **Then** kiss runs the shell command in the project root.
3. **Given** an `if:`, `switch:`, or `while:` step, **When**
   the engine runs it, **Then** the expression evaluator
   determines branch / iteration
   (`workflows/expressions.py`).
4. **Given** a `gate:` step, **When** the engine reaches it,
   **Then** the engine pauses and persists state for resume.
5. **Given** a `fan-out:` followed by `fan-in:`, **When** the
   engine runs, **Then** branches execute and results
   re-converge. **(Concurrency model — see RDEBT-012.)**

### Edge Cases

- **Workflow source missing** (id not in any catalog AND not
  a valid path): `cli/workflow.py:114-119` exits with code `1`.
- **Invalid YAML** in the workflow definition: `ValueError`
  surfaces (`cli/workflow.py:116-119`).
- **`command:` step run with no integration installed**:
  expected error path is unstated. See **RDEBT-011**.
- **`command:` step exits non-zero**: error propagation
  (halt / continue / retry) is unstated. See **RDEBT-021**.
- **Concurrency in fan-out**: thread vs. process vs. sequential
  is undocumented. See **RDEBT-012**.
- **Resume after kiss CLI version change**: state file may not
  be compatible — behaviour unstated. **(AI suggestion —
  confirm)**.
- **Gate that never resolves**: `kiss workflow status` shows
  the pending gate; the user must explicitly resume.
- **Network unavailable**: workflow engine itself does not
  perform network I/O; `command:` and `shell:` steps may
  invoke tools that do.
- **Catalog network access**: `kiss workflow catalog add <url>`
  may require network. See **RDEBT-023**.
- **Catalog source signed / verified?** see **RDEBT-022**.

## Requirements

### Functional Requirements

- **FR-001**: The CLI MUST expose workflow commands:
  `run <source> [-i key=value]…`,
  `resume`,
  `status`,
  `list`,
  `add <id-or-path>`,
  `remove <id>`,
  `search <query>`,
  `info <id>`
  (`cli/workflow.py:95,164,199,262,290,391,419,454`).
- **FR-002**: The CLI MUST expose
  `kiss workflow catalog list`,
  `kiss workflow catalog add <name> <src>`,
  `kiss workflow catalog remove <name>`
  (`cli/workflow.py:526,549,572`).
- **FR-003**: `run` MUST accept either a registered workflow
  id OR a path to a YAML workflow definition; selection is
  by checking whether `<source>` is a path that exists
  (`cli/workflow.py:97-113`).
- **FR-004**: `run` MUST load the definition via
  `WorkflowEngine.load_workflow` and run every step in order
  (`cli/workflow.py:113`).
- **FR-005**: `run` MUST support `-i key=value` parameters
  bound into the workflow's variable scope.
- **FR-006**: The engine MUST register the 10 built-in step
  types in `STEP_REGISTRY` at import time:
  `command`, `do-while`, `fan-in`, `fan-out`, `gate`, `if`,
  `prompt`, `shell`, `switch`, `while`
  (`workflows/__init__.py:43-65`).
- **FR-007**: A `command:` step MUST dispatch the named
  command via the active integration's
  `IntegrationBase.dispatch_command`
  (`integrations/base.py:147-225`); behaviour when no
  integration is installed is governed by **RDEBT-011**.
- **FR-008**: A `shell:` step MUST run the configured shell
  command in the project root.
- **FR-009**: A `prompt:` step MUST query the user for
  input (`workflows/steps/`).
- **FR-010**: A `gate:` step MUST pause execution, persist
  state, and exit such that `resume` can continue.
- **FR-011**: An `if:` / `switch:` step MUST branch on the
  value of an expression evaluated by the expression engine
  (`workflows/expressions.py`).
- **FR-012**: `while:` and `do-while:` MUST loop until an
  expression toggles, with a configurable maximum iteration
  guard. **(AI suggestion — confirm exact guard
  configuration.)**
- **FR-013**: `fan-out:` MUST execute its branches and
  `fan-in:` MUST re-converge results. The concurrency model
  (sequential / threaded / multi-process) is governed by
  **RDEBT-012**.
- **FR-014**: `resume` MUST reload the persisted workflow
  state and continue from the last incomplete step.
- **FR-015**: `status` MUST show the current step, history,
  and any pending gate.
- **FR-016**: `add <id-or-path>` MUST validate the workflow
  YAML, register it in the workflow registry, and persist the
  registration on disk.
- **FR-017**: `remove <id>` MUST drop the workflow from the
  registry.
- **FR-018**: `list` / `search` / `info` MUST be read-only
  inspection commands.
- **FR-019**: `catalog list` / `add` / `remove` MUST manage
  the registered catalogs.
- **FR-020**: The engine itself MUST NOT perform network
  I/O; only `command:` / `shell:` step targets may. The
  workflow loader MUST resolve registered ids via
  `_locate_bundled_workflow` (`installer.py:343-365`).
- **FR-021**: The engine MUST exit with non-zero codes on
  step failure; exact propagation rules are governed by
  **RDEBT-021**.

### Non-Functional Requirements

- **NFR-001 (Offline)**: The engine itself MUST not perform
  network I/O (ADR-003); user-defined `command:` / `shell:`
  steps may call tools that do — that is the workflow
  author's responsibility.
- **NFR-002 (Cross-platform)**: Linux, Windows; macOS
  asserted (RDEBT-005).
- **NFR-003 (Shell parity)**: `shell:` step MUST resolve to
  the platform-appropriate flavour; bundled workflow scripts
  MUST ship both `bash/` and `powershell/` (ADR-006 /
  ADR-015).
- **NFR-004 (Coverage)**: ≥ 80 % on changed files
  (RDEBT-006).
- **NFR-005 (Complexity / size)**: ≤ 40 LOC, complexity
  ≤ 10. `workflows/engine.py` is 778 LOC; individual
  functions inside MUST satisfy the limits per Principle
  III (RDEBT-007).
- **NFR-006 (Lint)**: Zero Ruff warnings on changed files
  (ADR-016).
- **NFR-007 (Determinism)**: A workflow run with the same
  inputs MUST produce the same step ordering and the same
  observable outputs (modulo external side-effects), per
  Principle IV.
- **NFR-008 (Resumability)**: State persistence MUST be
  durable enough that a crash mid-step leaves a recoverable
  state file.

### Key Entities

- **`WorkflowDefinition`** —
  `workflows/engine.py:28-77`. Parsed YAML.
- **`WorkflowEngine`** —
  `workflows/engine.py`. Orchestrates execution.
- **`STEP_REGISTRY`** —
  `workflows/__init__.py:20`. Module-level dict of step
  types registered at import time.
- **`StepBase` / `StepContext` / `StepResult`** —
  `workflows/base.py`. Common step contract.
- **Step types** — 10 built-in (per FR-006);
  `workflows/steps/`.
- **Bundled workflow** — `workflows/kiss/workflow.yml` (the
  default kiss SDD pipeline) —
  `_locate_bundled_workflow(installer.py:343-365)` resolves
  it.
- **Catalog** — `workflows/catalog.json` (bundled) plus any
  community catalogs added via `kiss workflow catalog add`.
- **State file** — persisted run state used by `resume`.
  Path / format implementation-defined.

## Success Criteria

### Measurable Outcomes

- **SC-001**: The bundled `kiss` workflow runs end-to-end on
  a fresh kiss project (`tests/test_workflows.py`).
- **SC-002**: A workflow paused at a `gate:` resumes from the
  same step on `kiss workflow resume`, with no re-execution
  of completed steps.
- **SC-003**: All 10 step types are exercised by at least
  one test in `tests/test_workflows.py`.
- **SC-004**: The engine itself performs zero network I/O —
  defended by the offline test suite (extended per ADR-017).
- **SC-005**: A workflow run with identical inputs produces
  identical step traces (up to timestamps).

## Assumptions

- The user has run `kiss init` so `.kiss/workflows/` exists.
- An integration is installed when running workflows that
  use `command:` steps. Behaviour without one is governed
  by **RDEBT-011**.
- Workflow authors honour the YAML schema validated by the
  engine on load.
- The expression language (`workflows/expressions.py`)
  evaluates pure expressions over the workflow's variable
  scope; it does not have side-effects.

## Out of Scope

- Authoring new step types (developer / contributor work;
  in-tree only per ADR-010).
- Distributed / multi-machine workflow execution.
- Sandboxing `shell:` step targets — they run in the user's
  shell with the user's permissions.
- Long-running daemon / always-on workflow scheduler — kiss
  is a CLI; workflow runs are foreground.
- Graphical workflow designer.

## Traceability

- **ADRs**: ADR-003 (offline), ADR-009 (analogous static
  registry principle for steps), ADR-010 (10 built-in step
  types, in-tree extension only), ADR-006 (parity).
- **Source modules**:
  `src/kiss_cli/cli/workflow.py:79-592` (12 commands);
  `src/kiss_cli/workflows/engine.py:1-778`;
  `src/kiss_cli/workflows/__init__.py:1-65`;
  `src/kiss_cli/workflows/base.py`;
  `src/kiss_cli/workflows/expressions.py`;
  `src/kiss_cli/workflows/steps/*`;
  `src/kiss_cli/installer.py:343-365`.
- **Tests**: `tests/test_workflows.py`.
- **Bundled assets**: `workflows/kiss/workflow.yml`,
  `workflows/catalog.json`.
- **Related specs**: `extension-management/spec.md` (hooks
  share the orchestration spirit), `integration-system/spec.md`
  (`command:` step depends on dispatch_command).
- **Related debts**: RDEBT-005, RDEBT-006, RDEBT-007,
  RDEBT-011 (no-integration behaviour),
  RDEBT-012 (concurrency),
  RDEBT-021 (error propagation),
  RDEBT-022 (catalog trust),
  RDEBT-023 (catalog network); cross-link TDEBT-010
  (dispatch_command call sites).
