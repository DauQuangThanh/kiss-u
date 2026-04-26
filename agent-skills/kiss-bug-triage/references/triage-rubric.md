# Triage rubric

Apply in order; the first bucket a bug lands in is where it goes.

1. **Critical severity OR active incident** → Fix now.
2. **Critical priority (customer-facing + visible)** → Fix now.
3. **High severity with workaround** → Next sprint.
4. **Medium severity + high recurrence** → Next sprint.
5. **Low severity + visible** → Defer.
6. **Low severity + low recurrence + no business case** → Won't
   fix (propose to PO; user confirms).

## What moves a bug between buckets

- A bug can **escalate** when new evidence lands (more users
  affected, regulatory implication, data loss reveal).
- A bug can **deescalate** when a workaround ships or the calling
  surface is deprecated.
- Movement is recorded as a comment on the bug file, never silently.

## Stale

- Open bug with no activity in > 30 days (configurable).
- Triage should decide: escalate, defer, or close with rationale.
- Never silently let a bug drift.
