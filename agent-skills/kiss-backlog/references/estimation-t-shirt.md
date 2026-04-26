# T-shirt sizing anchors

Use relative sizing. Anchor each size to a known past item whenever
possible; numbers are guide rails, not commitments.

| Size | Rough effort | Typical signal |
|:-:|---|---|
| **XS** | ≤ 1 day | CSS tweak, copy change, one-line config |
| **S**  | 1–3 days | Single-component change, no integrations |
| **M**  | 3–8 days | Multi-component, one integration, some tests |
| **L**  | 2–3 weeks | New feature area, multiple integrations |
| **XL** | 3+ weeks | Large — should be split before estimating |

## Splitting rules

- If an item is XL, try to split it into 2–4 L/M items along
  user-value lines.
- If a story can't be split, it's probably a research task — log as
  a separate spike before estimating.
- If two XS items share an area, consider bundling them so context
  cost is paid once.

## AI-authoring note

Only the team that will do the work can size reliably. The skill
writes down the team's estimate; it does not impose one.
