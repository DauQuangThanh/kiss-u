# Observability plan

**Date:** {date}
**Stack:** {stack}

## Three pillars

- **Logs** — structured JSON, one event per line, with
  `request_id` / `trace_id` correlation.
- **Metrics** — RED (rate, errors, duration) per endpoint + USE
  (utilisation, saturation, errors) per container.
- **Traces** — OpenTelemetry spans around I/O seams (DB, HTTP
  outbound, queue).

## SLIs + SLOs

| SLI | Target (SLO) | Alert threshold |
|---|---|---|
| Availability (successful requests / total) | {slo_avail}% | burn rate |
| Latency — p95 | ≤ {slo_p95_ms} ms | p95 > target for 10 min |
| Error rate | ≤ (100-{slo_avail})% | error budget burn |

## Alerts

- **Availability** — alert on fast burn (> 2% budget in 1h) and
  slow burn (> 10% budget in 24h).
- **Latency** — alert on sustained p95 breach + sudden step change.
- **Saturation** — alert at 80% utilisation; page at 90%.
- **Background** — alert on queue depth / dead-letter growth.

## Dashboards

- **Service overview** — RED per endpoint, error budget burn.
- **Dependencies** — DB / cache / IdP latency + error rates.
- **Deploys** — mark deploy events on every chart.

## Starter files

- `assets/alerts.sample.yml`
- `assets/dashboard.sample.json`
