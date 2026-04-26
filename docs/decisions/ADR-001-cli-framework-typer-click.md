# ADR-001: Use Typer + Click as the CLI framework

**Date:** 2026-04-26
**Status:** Proposed
**Decider:** (decider: TBD — confirm)

## Context

KISS is a CLI installer (`pyproject.toml:23` registers
`kiss = "kiss_cli:main"`). It needs sub-command grouping, nested
sub-Typer apps (`integration`, `preset`, `extension`, `workflow`,
`check`), help-text generation, and stable exit codes. The codebase
already uses Typer 0.24+ on Click 8.3+ (`pyproject.toml:7-8`,
`src/kiss_cli/cli/__init__.py:11-18`). All command modules under
`src/kiss_cli/cli/` rely on Typer's decorator API.

This ADR ratifies the existing choice as an architectural
decision so future contributions cannot quietly switch to
`argparse` or a homegrown parser.

## Decision

KISS uses **Typer ≥ 0.24.2** (with **Click ≥ 8.3.3** as Typer's
underpinning) as the sole CLI framework. New commands are added
as Typer functions or sub-apps; no other CLI framework may be
introduced without a superseding ADR.

## Consequences

- (+) Decorator-based command registration keeps each command
  module small and testable in isolation.
- (+) Help text is generated from docstrings — Principle V
  (continuous refactoring) costs less because there is no second
  doc surface to maintain.
- (+) Typer is built on Click, so existing Click ecosystem
  testing utilities (`CliRunner`) work.
- (−) Typer's reliance on type hints means signature changes
  ripple into help text; PR reviewers must check both.
- (−) Typer pins are tight (`>=0.24.2`); a future Typer major
  release may force a coordinated upgrade.

## Alternatives considered

- `argparse` — stdlib, zero-dep, but verbose for nested commands;
  no docstring-driven help.
- `Click` directly — viable, but Typer is a thin layer that gives
  the same primitives plus type-hint-driven argument parsing.
- `fire` — turns Python functions into CLIs auto-magically;
  rejected for opacity around argument parsing.

## Source evidence

- `pyproject.toml:7-8`
- `src/kiss_cli/cli/__init__.py:11-18`
- All `src/kiss_cli/cli/*.py` decorators
