# Test Strategy: {feature}

**Date:** {date}

## Scope

- **In scope:** <user stories / modules covered>
- **Out of scope:** <explicit exclusions>

## Levels of testing

| Level | Owner | Purpose |
|---|---|---|
| Unit | developer | isolated logic; run on every commit |
| Integration | developer / tester | module-to-module; run on PR |
| Contract | developer | API schema compatibility; run on PR |
| End-to-end | tester | user journeys; run nightly + on release branch |
| Performance | tester / SRE | SLA verification; run pre-release |
| Security | code-security-reviewer | SAST/DAST/dependency scan; run on PR |

## Risk-tiered priorities

Tiers: {risk_tiers}

| Tier | Signal | Coverage target |
|---|---|---|
| **High** | money movement / PII / regulatory | ≥ {coverage_target}% + e2e |
| **Medium** | core user journeys | {coverage_target}% unit + integration |
| **Low** | cosmetic / admin | unit only |

## Test environments

Available: {environments}

| Env | Data policy | Refresh cadence |
|---|---|---|
| dev | synthetic | per commit |
| staging | anonymised prod subset | daily |
| prod | live | n/a |

## Entry criteria (a build enters test)

- Unit tests pass
- Lint + type check pass
- Security scan shows no new High / Critical CVEs
- Feature flagged if merging before full test pass

## Exit criteria (a feature leaves test → release)

- All tiers at their coverage target
- Zero open Critical or High bugs against this feature
- Release runbook drafted (`kiss-deployment`)
- Stakeholders have reviewed the test summary

## Tooling

*(Populated by `kiss-test-framework` — linked once chosen.)*

## Open questions

See `test-debts.md`.
