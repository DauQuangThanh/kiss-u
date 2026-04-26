# Prioritisation frames — quick reference

When the user can't decide priority, offer one frame at a time.

## MoSCoW (simple, good for early-stage)

- **Must** — release fails without it
- **Should** — important, not vital; can defer one release
- **Could** — nice-to-have; ship if time permits
- **Won't** (this time) — explicitly out of scope this release

## WSJF — Weighted Shortest Job First (SAFe-style)

```text
WSJF = (user/business value + time criticality + risk reduction) / job size
```

Higher is better. Useful when multiple items compete for the same
capacity.

## RICE (good for continuous backlogs)

```text
RICE = (reach × impact × confidence) / effort
```

- Reach — users affected per period
- Impact — 0.25 / 0.5 / 1 / 2 / 3 (minimal → massive)
- Confidence — percentage (how sure are we about the numbers)
- Effort — person-months

## Value vs. effort quadrant (2×2, good for whiteboarding)

- **Quick wins** — high value, low effort → do now
- **Major projects** — high value, high effort → schedule
- **Fill-ins** — low value, low effort → parallel track
- **Thankless tasks** — low value, high effort → reconsider / drop

## AI-authoring note

The skill **proposes** a priority based on the frame the user picks
and the inputs they provide. The final priority is the user's call.
