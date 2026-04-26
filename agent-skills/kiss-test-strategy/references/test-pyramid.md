# Test pyramid — guidance

```text
         /\
        /E2E\         <- few, slow, most realistic
       /------\
      /INTEGR.\       <- some, medium speed
     /----------\
    /   UNIT     \    <- many, fast, isolated
   /______________\
```

## Ratios (rough)

- Unit : Integration : E2E ≈ 70 : 20 : 10 (by test count)
- Run-time budget is the inverse: unit should finish in under a
  couple of minutes; e2e can take tens.

## Anti-patterns

- **Ice-cream cone** — more e2e than unit. Brittle; slow feedback.
- **Hourglass** — lots of unit and e2e but no integration. Hidden
  bugs at module boundaries.
- **Cupcake** — heavy manual testing on top. Fine for one-off
  explorations; not a strategy.

## Guidance for risk-tiered projects

High-risk paths deserve **all three** levels (unit, integration, and
e2e). Low-risk paths may have unit only. The strategy document
names which path is which tier.
