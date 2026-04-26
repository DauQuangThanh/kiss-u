# Feature Specification: step-timeout-override

**Feature Slug**: `step-timeout-override`
**Created**: 2026-04-26
**Status**: Draft
**Branch**: `002-step-timeout-override`

## Problem Statement

The workflow engine's `command` step dispatches AI CLI commands
via `dispatch_command(timeout=600)` and the `shell` step uses a
hard-coded `timeout=300`. Neither step allows the workflow author
to override these defaults per step in the YAML definition.

For long-running AI tasks (e.g. implementing a large feature),
10 minutes may not be enough. For quick health checks, 5 minutes
is excessive. Workflow authors need a `timeout` field on each
step so they can tune behavior without touching source code.

## Source Specs

Implements requirements from:

- `docs/specs/integration-system/spec.md` — FR-006 (dispatch
  timeout clarification), Clarifications session 2026-04-26 Q1
- `docs/specs/workflow-engine/spec.md` — FR-007 (command step
  dispatches through IntegrationBase)

## User Stories

### US-1: Override timeout on a command step (Priority: P1)

As a workflow author, I want to set `timeout: 1800` on a command
step so that long-running AI tasks have 30 minutes instead of
the default 10.

**Acceptance Scenarios**:

1. **Given** a workflow YAML with `timeout: 1800` on a command
   step, **When** the engine executes it, **Then**
   `dispatch_command` is called with `timeout=1800`.
2. **Given** a command step without `timeout`, **When** the
   engine executes it, **Then** the default `600` is used.

### US-2: Override timeout on a shell step (Priority: P1)

As a workflow author, I want to set `timeout: 60` on a shell
step so quick checks fail fast instead of waiting 5 minutes.

**Acceptance Scenarios**:

1. **Given** a workflow YAML with `timeout: 60` on a shell step,
   **When** the engine executes it, **Then** `subprocess.run` is
   called with `timeout=60`.
2. **Given** a shell step without `timeout`, **When** the engine
   executes it, **Then** the default `300` is used.

### US-3: Validate timeout values (Priority: P2)

As a workflow author, I want invalid timeout values (negative,
zero, non-integer) to be caught at validation time, not at
runtime.

**Acceptance Scenarios**:

1. **Given** `timeout: -1` on a step, **When** the engine
   validates, **Then** it reports an error.
2. **Given** `timeout: "fast"` on a step, **When** the engine
   validates, **Then** it reports an error.

## Scope

**In scope**: `timeout` field on `command` and `shell` step
types; validation; default preservation.

**Out of scope**: Timeout on other step types (`prompt`, `gate`,
`if`, `switch`, `while`, `do-while`, `fan-out`, `fan-in`) —
these don't run external processes.
