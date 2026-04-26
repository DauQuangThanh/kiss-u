# Implementation Plan: step-timeout-override

**Branch**: `002-step-timeout-override` | **Date**: 2026-04-26 | **Spec**: [spec.md](spec.md)

## Summary

Add an optional `timeout` field to the `command` and `shell`
workflow step types so workflow authors can override the default
timeout per step in their YAML definition. Two source files
change, two test files added. Estimated delta: ~30 LOC + ~80 LOC
tests.

## Technical Context

**Language/Version**: Python 3.11+
**Primary Dependencies**: Typer, subprocess (stdlib)
**Testing**: pytest
**Target Platform**: Linux, Windows, macOS
**Project Type**: CLI tool
**Constraints**: Offline-only (ADR-003), ≤ 40 LOC / function (Principle III), ≥ 80% coverage

## Standards Check

| Gate | Status | Notes |
|------|--------|-------|
| Test-First (Principle II) | PASS | Tests before implementation |
| Small Units (Principle III) | PASS | Changes are < 10 LOC per function |
| Pure/Deterministic (Principle IV) | PASS | Timeout is a parameter, not side-effect |
| Coverage ≥ 80% | PASS | New tests cover all branches |
| Lint zero-warnings | PASS | Ruff via CI |

## Source Code (files to modify)

```text
src/kiss_cli/workflows/steps/
├── command/__init__.py   # Read timeout from config, pass to dispatch_command
└── shell/__init__.py     # Read timeout from config, pass to subprocess.run

tests/
├── test_step_timeout.py  # New: timeout override tests for both step types
└── test_workflows.py     # Existing: may need updates
```

## Work Packages

### WP-1: `command` step timeout override

**Source**: `src/kiss_cli/workflows/steps/command/__init__.py`

**Changes**:

1. In `_dispatch_via_integration`, read `config.get("timeout", 600)` and pass it to `dispatch_command(timeout=...)`.
2. In `validate`, check that `timeout` (if present) is a positive integer.

### WP-2: `shell` step timeout override

**Source**: `src/kiss_cli/workflows/steps/shell/__init__.py`

**Changes**:

1. In `execute`, replace hard-coded `timeout=300` with `config.get("timeout", 300)`.
2. Update the timeout error message to use the actual value.
3. In `validate`, check that `timeout` (if present) is a positive integer.

## Dependency Graph

```text
WP-1 (command step)  ── independent
WP-2 (shell step)    ── independent
```

Both can be done in parallel.

## Research

No unknowns — the implementation pattern is straightforward:
read a YAML key, pass it as a parameter.

## Data Model

No entity changes. The only schema change is the YAML step
config gaining an optional `timeout: int` field:

```yaml
steps:
  - id: implement
    type: command
    command: kiss.implement
    timeout: 1800    # 30 minutes (default: 600)
  - id: lint
    type: shell
    run: ruff check src/
    timeout: 60      # 1 minute (default: 300)
```
