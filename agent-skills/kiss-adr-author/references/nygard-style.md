# Michael Nygard ADR style — quick reference

An ADR is a short, dated record of an architectural decision that
captures the **context**, the **decision**, and the **consequences**.
Goal: a future team member can read it and understand why without
interviewing the original decider.

## Sections

- **Title** — imperative sentence, e.g. "Use PostgreSQL as the
  primary store", not "Database selection".
- **Status** — `Proposed` / `Accepted` / `Deprecated` / `Superseded`.
  An ADR is never deleted; superseded ADRs link forward to the
  replacement.
- **Context** — the forces at play: functional requirement, quality
  attribute, constraint, time pressure. Two short paragraphs max.
- **Decision** — one active-voice statement. "We will use X." Not
  "We might consider X." If you can't write that sentence, the
  decision isn't ripe.
- **Consequences** — both positive and negative outcomes that
  follow. Include what becomes easier, what becomes harder, and
  what future decisions are constrained.

## Anti-patterns

- **Too long** — if it's more than one page, it's probably a design
  document, not an ADR. Link to design docs from the ADR.
- **Decision dressed as context** — "We chose X because Y" belongs
  in Decision, not Context.
- **Vague consequences** — "will improve performance" is not a
  consequence; "p95 latency target moves from 400 ms to 200 ms" is.
- **No alternatives** — readers can't evaluate a decision without
  knowing what else was on the table.

## Versioning

Do not edit accepted ADRs. Write a new ADR that supersedes the
older one. The template's `ADR_SUPERSEDES` field emits a
`Supersedes: ADR-NNN` line, and the reviewer should update the
superseded ADR's status to `Superseded` with a back-link.
