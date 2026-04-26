# Severity vs. priority

These are **two independent axes**. Don't collapse them.

## Severity — impact on the system / user

| Band | Signal |
|---|---|
| **Critical** | data loss, security breach, total outage |
| **High** | core feature unusable; major revenue impact |
| **Medium** | workaround exists; UX degradation |
| **Low** | cosmetic; rare edge |

## Priority — how soon we fix

| Band | Signal |
|---|---|
| **Critical** | fix now; page oncall |
| **High** | fix this week / sprint |
| **Medium** | fix next sprint |
| **Low** | fix when convenient |

## Common combinations

- **Critical severity + Critical priority** — incident response.
- **Critical severity + Low priority** — affects nobody right now
  (e.g. disaster-recovery gap no-one is exercising). Rare; audit it.
- **Low severity + High priority** — visible to a key customer
  mid-demo. Deal with it.

The AI proposes both; the user confirms.
