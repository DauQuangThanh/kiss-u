# Waterfall phase gates

Formal gates between phases. Each gate must be closed (signed off)
before the next phase begins. Changes after a gate is closed require
Change Control Board approval.

| # | Gate | Gate criteria | Typical artefacts |
|---|---|---|---|
| 1 | Requirements | All requirements approved, signed off by stakeholders | `specs/**/spec.md` |
| 2 | Design | Architecture approved, technical design complete | `docs/architecture/**`, `docs/decisions/ADR-*.md`, `docs/design/**` |
| 3 | Development | All code written, reviewed, integrated | code, PRs, code-review records |
| 4 | Testing | All tests passed, UAT approved | `docs/testing/**`, test-execution reports |
| 5 | Release | Deployment plan reviewed, go-live approved | `docs/operations/deployment.md`, runbooks |

## Sign-off record

When a gate closes, the PM records the sign-off in the change log:

```text
GATE-N: <name>
Signed off: YYYY-MM-DD by <name> (<role>)
Evidence: <path to artefacts>
Open items deferred: <list PMDEBT or CR ids if any>
```

The AI skill drafts this record but does not produce the sign-off
itself — that is a human authority action.
