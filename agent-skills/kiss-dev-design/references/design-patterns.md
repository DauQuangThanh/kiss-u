# Design patterns — one-line chooser

Pick the pattern that matches the **hard constraint**, not the one
that's fashionable.

| Pattern | When to pick | Trade-off |
|---|---|---|
| **Layered** | Simple CRUD services; small team | Risk of anaemic domain; framework tightly coupled |
| **MVC** | Request-response web apps; frameworks expect it | Controllers become fat; hard to test without framework |
| **Hexagonal (ports + adapters)** | You'll swap infra (DB / queue / IDP) without changing domain | More files; steeper onboarding |
| **Onion / Clean** | Same as hexagonal, plus explicit dependency direction enforcement | Even more files; domain becomes the centre of gravity |
| **Event-driven** | Long-running workflows; independent services | Debugging distributed flows is harder |
| **CQRS / ES** | Read-heavy with divergent read shapes; audit-first domains | Complexity ramps quickly; steep learning curve |

## Guidance

- If in doubt between Hexagonal and Onion, pick **Hexagonal** — the
  distinction is marginal and Hexagonal is the more commonly
  understood term.
- If the team has never done CQRS/ES, don't start with it on a
  new product. Start simple; evolve if the need appears.
- Pattern choice belongs in an ADR.
