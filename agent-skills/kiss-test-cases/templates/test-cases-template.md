<!-- markdownlint-disable MD024 -->
# Test cases: {feature}

**Date:** {date}

## Legend

- **Level:** unit / integration / e2e
- **Type:** positive / negative / boundary
- **Effort:** XS / S / M / L (T-shirt, informational)

## Cases

### US-NN — AC-NN: <AC title>

| TC id | Level | Type | Title | Preconditions | Steps | Expected |
|---|---|---|---|---|---|---|
| TC-01 | e2e | positive | <short> | <setup> | <steps> | <outcome> |
| TC-02 | e2e | negative | <short> | <setup> | <steps> | <outcome> |
| TC-03 | e2e | boundary | <short> | <setup> | <steps> | <outcome> |

### US-NN — AC-NN: <next AC>

…

## Traceability

Every AC in acceptance.md should appear above with ≥ 1 test case
of type "positive". Cases without an AC anchor are flagged in
`test-debts.md` as a traceability gap.
