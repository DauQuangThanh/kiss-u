# Change-request impact assessment — guide

For each CR, assess four dimensions. Use H / M / L consistently per
these rules.

## Scope impact

| Band | Signal |
|:-:|---|
| **H** | New phase, new major feature, new out-of-scope obligation, new compliance regime |
| **M** | Adds a user story or two; touches existing features meaningfully |
| **L** | Cosmetic / copy / minor UX; does not change functional scope |

## Schedule impact

| Band | Signal |
|:-:|---|
| **H** | > 10% of remaining schedule, or shifts a milestone past target date |
| **M** | Noticeable; absorbable with replanning inside the current phase |
| **L** | Minimal; fits in the next unclaimed slot |

## Budget impact

| Band | Signal |
|:-:|---|
| **H** | > 10% of remaining budget, or requires new procurement |
| **M** | Noticeable; reallocatable within existing budget categories |
| **L** | Negligible; within day-to-day variance |

## Quality impact

| Band | Signal |
|:-:|---|
| **H** | New security/compliance obligation, or reduces existing NFR commitments |
| **M** | Adds a test surface that needs new coverage |
| **L** | No measurable quality change |

## Priority derivation (AI proposal)

After assigning H/M/L per dimension, suggest a priority:

- Any H on **Scope** AND any H on **Schedule** → **🔴 Critical**
- H on **Quality** (security, compliance, privacy) → **🔴 Critical**
- One H on any dimension → **🟡 High**
- All M or below, with at least one M → **🟢 Medium**
- All L → **🔵 Low**

The AI proposes the priority; the user (and CCB) own the final call.

## What to always include in the "reason for request"

- Who initially raised it (stakeholder, customer, audit finding)
- Problem it solves (user pain, regulatory requirement, tech debt)
- Consequence of doing nothing

Without these three, a CR is not reviewable and should be logged as a
debt in `pm-debts.md` rather than dispatched.
