# C4 diagrams in plain Mermaid

Mermaid doesn't have first-class C4 blocks — we use `flowchart`
with conventions so every reader sees the same thing.

## Conventions

- **Person / actor** — square-bracket node with 👤 prefix.
- **System (subject)** — stadium node `((name))` for Level 1; plain
  subgraph for Levels 2–3.
- **Container** — square-bracket node with an emoji icon and an
  italic technology name on line 2.
- **Database** — cylinder `[()]`.
- **External system** — same node style but with the italic text
  "external" on line 2.
- **Edge label** — the protocol or interaction type, not "calls".
- **Grouping** — `subgraph` with the system name as the label.

## Mermaid tips

- Use `<br/>` to break to a second line inside a node label.
- Use `<em>...</em>` for the italic tech hint.
- Use `LR` for Level 1, `TB` for Level 2, whichever reads best for
  Level 3.
- Keep node count under ~12 per diagram. If you need more, split
  by subsystem.

## Anti-patterns

- **Code-level detail on the container diagram** — classes don't
  belong here; they live in design.md.
- **Unlabelled edges** — every arrow has a protocol / purpose.
- **Mixing zoom levels on one diagram** — if some nodes are
  containers and some are components, split into two.
- **Implementation tools instead of responsibility** — "Kafka" is
  a technology; the node's name should be "Event bus".
