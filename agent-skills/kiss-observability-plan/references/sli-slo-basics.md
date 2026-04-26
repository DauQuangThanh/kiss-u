# SLI / SLO / error budgets — basics

## Terms

- **SLI** — Service Level Indicator. A measured ratio or number
  (e.g. "successful requests / total requests" over 5 minutes).
- **SLO** — Service Level Objective. Target for an SLI over a
  window (e.g. "99.9% availability over 28 days").
- **Error budget** — 100% − SLO. At 99.9% you have 0.1% "budget"
  to burn per window (about 43 min / month).

## Good SLIs

- **Availability** — success ratio of eligible requests.
- **Latency** — p95 or p99 of a chosen endpoint / journey.
- **Quality** — rate of correctness (e.g. returns correct result).
- **Freshness** — max age of data served.

## Avoid

- Raw request counts (affected by traffic, not quality).
- CPU / memory percentages (symptoms, not user-visible).
- Aggregate averages that hide tails.

## Alerting rules

- Alert on budget **burn rate**, not absolute thresholds. Fast
  burn + slow burn rules together catch outages and drift.
- Never page on warnings — if it doesn't need action in 5
  minutes, it's not a page.
