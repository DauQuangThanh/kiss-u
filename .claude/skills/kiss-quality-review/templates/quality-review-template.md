# Code Quality Review: {feature}

**Date:** {date}
**Scope:** {scope}

## Summary

- **Files reviewed:** <count>
- **High findings:** <count>
- **Medium findings:** <count>
- **Low findings:** <count>
- **Composite quality score:** <0–100>  *(AI proposal)*

## High-severity findings

### CQ-01: <short title>

- **File:** `path/to/file.ts:42-58`
- **Smell:** <e.g. God function — 180 lines, 7 responsibilities>
- **Why it matters:** <impact on maintainability / testability>
- **Proposed fix:** <outline, not a patch>

## Medium-severity findings

…

## Low-severity findings

…

## Complexity hotspots

| File | Function | Cyclomatic | Lines |
|---|---|:-:|:-:|
| `src/foo.ts` | `doThing` | 14 | 72 |

## SOLID / DRY / KISS scorecard

| Principle | Rating | Notes |
|---|---|---|
| **S**ingle Responsibility | 🟢 / 🟡 / 🔴 | |
| **O**pen/Closed | | |
| **L**iskov Substitution | | |
| **I**nterface Segregation | | |
| **D**ependency Inversion | | |
| **DRY** | | |
| **KISS** | | |

## Debt

All findings with severity High / Medium are duplicated in
`{context.paths.docs}/reviews/quality-debts.md` as `CQDEBT-NN`
entries so they persist beyond this review.
