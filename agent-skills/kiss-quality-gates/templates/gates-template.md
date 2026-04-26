# Quality Gates: {feature}

**Date:** {date}

## PR gate (every PR must pass)

| Check | Threshold | Tool |
|---|---|---|
| Unit tests pass | 100% | <framework> |
| Coverage | ≥ {cov_pr}% | <coverage tool> |
| Lint | 0 errors | <linter> |
| Type check | 0 errors | <type checker> |
| Security scan | 0 Critical, ≤ {max_high} High new | <SAST tool> |
| Secret scan | 0 findings | <scanner> |

## Merge gate (in addition to PR gate)

| Check | Threshold | Tool |
|---|---|---|
| Integration tests | 100% pass | <framework> |
| Contract tests | 100% pass | <framework> |
| Dependency audit | 0 Critical open | <audit tool> |

## Release gate (in addition to merge gate)

| Check | Threshold | Tool |
|---|---|---|
| E2E tests | 100% pass on staging | <framework> |
| Coverage | ≥ {cov_release}% | <coverage tool> |
| Performance budget (p95) | ≤ {p95_ms} ms under SLA load | <perf tool> |
| Security — CRITICAL open | ≤ {max_crit} | <SAST/DAST> |
| Release runbook | present + reviewed | manual |

## Waivers

All waivers require a written reason linked from this file. A
waiver expires at the next release unless renewed.

| Gate | Waiver reason | Expires |
|---|---|---|
