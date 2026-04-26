# ADR-012: Two-mode UX for custom agents (`interactive` + `auto`)

**Date:** 2026-04-26
**Status:** Proposed
**Decider:** (decider: TBD — confirm)

## Context

`CLAUDE.md` ("Every custom agent supports two modes") establishes
that every role-agent under `subagents/` (architect,
developer, technical-analyst, business-analyst, …) accepts two
modes of operation:

- `interactive` (default) — the agent runs a beginner-friendly
  questionnaire, asks one short question at a time, recommends
  defaults, and pauses for user confirmation before writing.
- `auto` — the agent skips the questionnaire, applies sensible
  defaults grounded in standards + upstream artefacts, records
  every non-trivial decision to
  `<paths.docs>/agent-decisions/<agent>/<YYYY-MM-DD>-decisions.md`,
  and proceeds without confirmation pauses.

Mode selection rules (CLAUDE.md): keyword in first message
("in auto mode, …" / "interactively, …") wins; environment
variable `KISS_AGENT_MODE=auto` is the fallback; default is
`interactive`. Mode propagates to the skill layer: `auto` →
`--auto` (Bash) / `-Auto` (PowerShell) on the underlying scripts.

This convention is currently expressed in `CLAUDE.md` and in
each role-agent's prompt (`subagents/<role>/instructions.md`),
but no ADR pins it. Without an ADR a future contribution could
quietly drop one of the modes or change the propagation rules.

## Decision

Every custom-agent (in `subagents/`) and every architect-
adjacent skill (in `agent-skills/`) MUST:

1. Honour two modes: `interactive` and `auto`.
2. Resolve the active mode via the precedence:
   first-message keyword > `KISS_AGENT_MODE` env > default
   `interactive`.
3. In `auto` mode:
   - skip questionnaires;
   - record every non-trivial decision to
     `<paths.docs>/agent-decisions/<agent>/<YYYY-MM-DD>-decisions.md`
     using the four kinds:
     `default-applied`, `alternative-picked`,
     `autonomous-action`, `debt-overridden`;
   - propagate `--auto` (Bash) / `-Auto` (PowerShell) to
     skill scripts.
4. In `interactive` mode:
   - run the agent's questionnaire (per-agent),
   - honour `preferences.confirm_before_write`,
   - never invoke skill scripts with the `--auto` flag.

The four decision kinds, the agent-decisions file path, and the
write_decision / `Write-Decision` helpers in `common.sh` /
`common.ps1` are part of this contract.

## Consequences

- (+) Users with limited technical background can opt into
  `interactive` and get walked through the work.
- (+) Power users / CI can run agents in `auto` for
  reproducibility.
- (+) Decision-log files give the user an after-action audit
  even in `auto`.
- (−) Every new role-agent must implement both modes; there is no
  "one-mode" shortcut.
- (−) The mode-keyword detection ("in auto mode, …") is a
  string-match heuristic; a determined user could phrase it in a
  way the agent misses. Documented in each prompt; not
  programmatically enforced.

## Alternatives considered

- **Single mode (always interactive)** — rejected; defeats CI /
  scripted use.
- **Single mode (always auto)** — rejected; first-time users
  benefit from the questionnaire.
- **Three modes (interactive, semi-auto, auto)** — premature
  (YAGNI); two modes have not yet been fully exercised.

## Source evidence

- `CLAUDE.md` "Every custom agent supports two modes"
- `subagents/architect/instructions.md` (this very file's
  prompt)
- `agent-skills/*/scripts/bash/common.sh` (`write_decision`)
- `agent-skills/*/scripts/powershell/common.ps1`
  (`Write-Decision`)
