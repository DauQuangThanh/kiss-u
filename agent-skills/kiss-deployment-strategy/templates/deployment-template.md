# Deployment strategy + runbook

**Date:** {date}
**Release model:** {model}
**Canary bake (minutes):** {bake_min}
**Environments:** {envs}

## Promotion flow

1. Merge to `main` → auto-deploy to **staging**.
2. Staging passes e2e + security scan.
3. Manual approval gate.
4. **Canary** to 5% of prod traffic for {bake_min} minutes.
5. Observe: error budget burn, p95 latency, saturation.
6. If clean → roll out to 100%. If not → roll back (see below).

## Rollback

**Triggers (any one):**

- Error rate > 2× baseline for 5 minutes
- p95 latency > 1.5× baseline for 10 minutes
- Any Critical alert

**Procedure:**

1. Flip traffic to the previous stable deployment.
2. Post a short summary to the incident channel (by the user).
3. File a post-mortem issue; link the offending commit + the
   change-register row.

## Feature flags

- New features deploy behind a flag, default-off.
- Flag → ramp → remove-flag. One release per phase.
- Never leave a flag in the code beyond the next release without
  an explicit `OPSDEBT`.

## Release notes (seed)

Pulled from `docs/bugs/change-register.md` + the merged PRs since
the last release. User reviews + edits before publishing. AI does
not publish.

## Environments

| Env | Purpose | Data | Access |
|---|---|---|---|
| dev | developer sandbox | synthetic | engineers |
| staging | pre-prod verification | anonymised subset | engineers + QA |
| prod | live | live | on-call only; infra via IaC only |
