# Release models — quick reference

| Model | Description | Pros | Cons |
|---|---|---|---|
| **Canary** | Small % of traffic to new version; grow if clean | Catches issues without full exposure; measurable risk | Requires routing + per-version metrics |
| **Blue-green** | Two identical envs; flip traffic atomically | Fast rollback; easy verification | Double infra cost; long-running migrations painful |
| **Rolling** | Replace instances gradually | No traffic split needed; simple | Harder to roll back quickly; mixed versions in flight |
| **Recreate** | Stop old, start new | Simplest; good for single-user tools | Downtime |

## Picking

- **Prod with SLA** — canary.
- **Bursty traffic + simple stack** — blue-green.
- **Background workers** — rolling often suffices.
- **Single-tenant / dev tool** — recreate is fine.

## Always have

- A rollback path that takes < 5 minutes to execute.
- A pre-deploy checklist (migrations? feature flags? env vars?).
- A post-deploy check window based on the monitoring SLIs.
