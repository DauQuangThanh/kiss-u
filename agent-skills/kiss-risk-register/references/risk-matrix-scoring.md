# Risk matrix scoring

## Likelihood scale (1–5)

| Value | Band | Meaning |
|:-:|---|---|
| 1 | Rare | Unlikely to occur in the project lifespan |
| 2 | Unlikely | Possible but not expected |
| 3 | Possible | Has occurred on similar projects |
| 4 | Likely | Expected to occur at some point |
| 5 | Almost certain | Already occurring or imminent |

## Impact scale (1–5)

| Value | Band | Meaning |
|:-:|---|---|
| 1 | Negligible | Minor inconvenience; no project impact |
| 2 | Minor | Small schedule/cost variance; no quality impact |
| 3 | Moderate | Notable schedule/cost impact; recoverable |
| 4 | Major | Major slip, quality loss, or budget overrun |
| 5 | Critical | Project failure or material harm |

## Scoring grid

| Impact ↓ / Likelihood → | 1 | 2 | 3 | 4 | 5 |
|:-:|:-:|:-:|:-:|:-:|:-:|
| **1** | 🟢 1 | 🟢 2 | 🟢 3 | 🟢 4 | 🟢 5 |
| **2** | 🟢 2 | 🟢 4 | 🟢 6 | 🟡 8 | 🟡 10 |
| **3** | 🟢 3 | 🟢 6 | 🟡 9 | 🟡 12 | 🔴 15 |
| **4** | 🟢 4 | 🟡 8 | 🟡 12 | 🔴 16 | 🔴 20 |
| **5** | 🟢 5 | 🟡 10 | 🔴 15 | 🔴 20 | 🔴 25 |

## Bands

- **1–7 Green** — document and monitor; no active mitigation required.
- **8–14 Amber** — mitigation plan required; review at least monthly.
- **15–25 Red** — immediate mitigation required; escalate to sponsor;
  review weekly until reduced to amber or better.
