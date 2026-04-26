# Dependency graph heuristics

## Nodes

- Group by **module folder**, not individual files — files inside
  one folder usually co-vary.
- Aggregate external deps into a single "External" node per ecosystem
  (npm / PyPI / Maven) to keep the diagram readable.

## Edges

- Solid arrow: direct import / call.
- Dashed arrow: dynamic / runtime lookup (less safe).
- Label with the edge's nature only when non-obvious.

## Cycle detection

- Any cycle is a smell — log each as an `ANALYSISDEBT-NN`.
- Frequent cycle patterns: shared types in a "utils" module that
  pulls in domain code; circular dependencies between adapters
  and domain (fix by inverting the dependency).

## Size limits

- If the graph exceeds ~25 nodes, split by subsystem.
- Keep the per-file graph out of this artefact — it belongs to an
  IDE tool, not a design doc.
