# Complexity thresholds

These are defaults. Teams adjust in `kiss-standardize` and the skill
reads them from the project standards when present.

## Cyclomatic complexity (per function)

| Band | Value |
|---|---|
| Green | ≤ 10 |
| Amber | 11–20 |
| Red | > 20 |

## Function length (source lines of code)

| Band | Value |
|---|---|
| Green | ≤ 50 |
| Amber | 51–100 |
| Red | > 100 |

## File length

| Band | Value |
|---|---|
| Green | ≤ 300 |
| Amber | 301–500 |
| Red | > 500 |

## Parameter count

| Band | Value |
|---|---|
| Green | ≤ 4 |
| Amber | 5–7 |
| Red | > 7 (strong smell — consider a parameter object) |

## Nesting depth

| Band | Value |
|---|---|
| Green | ≤ 3 |
| Amber | 4 |
| Red | ≥ 5 |

## AI-authoring note

Report the **three worst offenders** per metric in the review —
don't dump every function above a threshold. The goal is to drive
action, not generate noise.
