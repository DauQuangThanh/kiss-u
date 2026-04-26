# ADR-010: Workflow engine ships ten built-in step types; extension is in-tree only

**Date:** 2026-04-26
**Status:** Proposed
**Decider:** (decider: TBD — confirm)

## Context

KISS includes a workflow engine (`src/kiss_cli/workflows/`) that
executes YAML-defined sequences against the installed AI
providers. The engine supports 10 built-in step types
(`workflows/__init__.py:43-65`):

`command`, `do-while`, `fan-in`, `fan-out`, `gate`, `if`,
`prompt`, `shell`, `switch`, `while`.

Step type registration goes through `_register_step()` inside
`workflows/__init__.py`; there is no out-of-tree mechanism. New
step types ship as files under `workflows/steps/` and an entry in
the registry.

Mirroring ADR-009 for integrations, the workflow engine takes the
same closed-set posture: a step type is code (not config) and is
shipped in the wheel.

## Decision

The workflow engine maintains a **closed set of in-tree step
types**:

- Built-in step types live in `src/kiss_cli/workflows/steps/`.
- New step types are added by code change + ADR + test, never via
  user-side plugins.
- Workflow YAML files reference step types by string key
  (`type: command`, `type: shell`, …); unknown keys raise an
  error in `WorkflowEngine.load_workflow`.
- Workflows themselves *are* user-extensible — users can ship
  their own YAML workflow under `<project>/.kiss/workflows/<id>/`
  and reference it via `kiss workflow run <id>`. They just cannot
  introduce new *step types* without contributing upstream.

## Consequences

- (+) Every step type is exercised by CI; users cannot accidentally
  invoke an unsupported one.
- (+) The 10 step types cover today's needs (control flow:
  `if`/`switch`/`while`/`do-while`, parallelism:
  `fan-out`/`fan-in`, gating: `gate`, integration calls: `command`,
  shell-out: `shell`, AI prompts: `prompt`).
- (+) A user can build sophisticated workflows from the existing
  primitives without touching Python.
- (−) Adding a new step type is a code change with full PR
  review and a test — mild friction for niche use cases.
- (−) The 10 step types overlap (`while` vs. `do-while`, `if`
  vs. `switch`); reviewers must guard against future "11th"
  primitives that duplicate existing ones.

## Alternatives considered

- **`entry_points` plugin model for step types** — rejected for
  the same reasons as ADR-009 (offline-runtime / trust).
- **Single generic `step` type with embedded Python** — rejected;
  would let workflow YAML contain executable code, breaking the
  audit story.
- **Smaller core set + community plugin gallery** — premature
  (YAGNI).

## Source evidence

- `src/kiss_cli/workflows/__init__.py:20,36-38,43-65`
- `src/kiss_cli/workflows/engine.py` (WorkflowEngine,
  WorkflowDefinition)
- `src/kiss_cli/workflows/steps/` (10 modules)
