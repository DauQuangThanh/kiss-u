# ADR-006: Cross-platform script parity — every skill ships Bash + PowerShell

**Date:** 2026-04-26
**Status:** Proposed
**Decider:** (decider: TBD — confirm)

## Context

KISS targets developers on macOS, Linux, and Windows
(`CLAUDE.md` "Cross-platform shells"). Skills frequently include
helper scripts that the AI provider (or the user) invokes — for
example, `kiss-arch-intake` ships a script that scaffolds the
intake template. Picking only Bash would lock out Windows users
who do not have Git-for-Windows MSYS bash installed; picking only
PowerShell would lock out macOS / Linux users.

The current convention (visible in
`agent-skills/_template/scripts/`) is that **every** skill ships
both `scripts/bash/<name>.sh` and `scripts/powershell/<name>.ps1`,
with shared logic in `common.sh` / `common.ps1`. The runtime
selects the flavour at install time
(`installer.py:626-637`) and bundles the appropriate scripts via
`skill_assets.py:79-127`.

The standards' Quality Gates already mandate parity ("any change
to a Bash script MUST be mirrored in the equivalent PowerShell
script (and vice versa) in the same PR"). This ADR promotes that
team rule to an architectural-level decision so it can be
enforced mechanically.

## Decision

Every KISS skill that ships executable script support **MUST**
ship both a Bash and a PowerShell flavour, with shared semantics:

- Folder layout per skill:

  ```text
  agent-skills/kiss-<name>/
    scripts/
      bash/
        common.sh
        <subcommand>.sh
      powershell/
        common.ps1
        <subcommand>.ps1
  ```

- Both flavours must accept the same argument names (mode flags
  like `--auto` / `-Auto`, output paths, etc.).
- CI must exercise both flavours: see `tests/conftest.py::_has_working_bash()`
  and the matrix in `.github/workflows/test.yml:30-55`.
- A parity test (TDEBT-021) is recommended to mechanically verify
  every Bash script has a sibling `.ps1` with the same set of
  exported entry points.

## Consequences

- (+) Windows-first developers can use KISS without MSYS bash.
- (+) macOS / Linux developers do not pay a `pwsh` install tax.
- (+) The team rule is now architecturally pinned — a contributor
  cannot ship a Bash-only skill without violating an ADR.
- (−) Doubles the script surface area; every behaviour change is
  done twice.
- (−) Subtle semantic drift between flavours is the most common
  parity bug; the recommended parity test (TDEBT-021) is not yet
  in place.

## Alternatives considered

- **Bash only with WSL prerequisite** — rejected; WSL is heavy
  and not always permitted in regulated environments.
- **PowerShell Core only** — rejected; macOS / Linux developers
  rarely have it pre-installed.
- **Python-only scripts** — rejected; many skill scripts wrap
  shell-native operations (`sed`, `grep`, `find`) and a Python
  wrapper would be slower and less idiomatic.

## Source evidence

- `CLAUDE.md` "Cross-platform shells"
- `agent-skills/_template/scripts/` (template structure)
- `src/kiss_cli/skill_assets.py:1-23,79-127`
- `src/kiss_cli/installer.py:626-637`
- `docs/standards.md` Quality Gates → "Parity"
