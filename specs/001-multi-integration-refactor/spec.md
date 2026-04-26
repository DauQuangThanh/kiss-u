# Feature Specification: multi-integration-refactor

**Feature Slug**: `multi-integration-refactor`
**Created**: 2026-04-26
**Status**: Draft
**Branch**: `001-multi-integration-refactor`

## Problem Statement

The kiss CLI source code enforces a single-integration-post-init
policy that contradicts the updated specs. Six source-code areas
need refactoring to align with the clarified requirements:

1. `integration.json` stores a singular `integration` key — must
   become `integrations: [list]`.
2. `kiss integration install` refuses when another integration is
   installed — must allow adding alongside existing ones.
3. `kiss integration uninstall` assumes a single integration —
   must support named uninstall and `--all`.
4. `kiss integration upgrade` operates on a single integration —
   must support named upgrade and `--all`.
5. `dispatch_command` ignores timeout when streaming — must
   enforce SIGTERM/SIGKILL on timeout with exit code `124`.
6. `_install_shared_infra` overwrites `context.yml` — must merge
   (preserve user customizations, add new schema keys only).

## Source Specs

This refactoring implements requirements from:

- `docs/specs/integration-system/spec.md` — FR-006 (dispatch
  timeout clarification: SIGTERM/SIGKILL, exit 124), FR-009a
  (check output improvements), FR-018 (primary folder only),
  Clarifications session 2026-04-26
- `docs/specs/kiss-install/spec.md` — FR-004 (multi-integration)
- `docs/specs/kiss-uninstall/spec.md` — FR-001, FR-003, FR-010
- `docs/specs/kiss-upgrade/spec.md` — FR-001, FR-002, FR-016
- `docs/specs/kiss-init/spec.md` — FR-013, SC-004

## Scope

**In scope**: Source code changes to `cli/integration.py`,
`installer.py`, `integrations/base.py`, `cli/check.py`,
`context.py`, and their tests.

**Out of scope**: Skill renames (RDEBT-031), AI provider
narrowing (RDEBT-024), asset integrity wiring (RDEBT-003),
subagent per-AI rendering (RDEBT-035).
