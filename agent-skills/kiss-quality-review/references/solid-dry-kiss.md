# SOLID / DRY / KISS

Canonical principles + the smells that typically indicate a
violation.

## SOLID

| Letter | Principle | Typical smell |
|---|---|---|
| **S** | Single Responsibility | God class / function; "and" in the name |
| **O** | Open/Closed | Adding a case triggers edits in many switch statements |
| **L** | Liskov Substitution | Subclass overrides throw NotImplemented; `instanceof` branches |
| **I** | Interface Segregation | Clients depend on methods they never call |
| **D** | Dependency Inversion | High-level code imports low-level concrete types directly |

## DRY (Don't Repeat Yourself)

Not about text duplication — about **knowledge duplication**. Two
places that would both change in response to the same business
rule violate DRY. Two lines that happen to look alike but would
change for different reasons do not.

## KISS (Keep It Simple, Stupid)

- Prefer the straightforward over the clever.
- Reject abstraction without three concrete use cases.
- A conditional you can replace with a lookup table is usually
  simpler.

## When to flag

- **High** — a principle is broken in a way that will bite
  within weeks (e.g. a god class that multiple teams must edit).
- **Medium** — a principle is broken but contained (one team, one
  file).
- **Low** — a principle is bent; noteworthy but not a fire.
