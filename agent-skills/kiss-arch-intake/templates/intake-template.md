# Architecture Intake

**Date:** {date}
**Feature / scope:** {feature}

## 1. Quality attributes — ranked (1 highest → 5 lowest)

1. <e.g. Security>
2. <e.g. Performance>
3. <e.g. Maintainability>
4. …
5. …

## 2. Hard constraints

- Cloud / on-prem: <e.g. AWS-only, on-prem>
- Approved vendors: <list>
- Required languages / frameworks: <list>
- Licence restrictions: <e.g. no GPL>
- Data-residency rules: <e.g. EU-only>
- Compliance regimes: <e.g. GDPR, HIPAA, PCI-DSS>

## 3. Team context

- Team size: {team_size_band}
- Existing skill set: <list>
- Hiring plans: <list>

## 4. Operational envelope

- Concurrent users / total users: <numbers>
- Peak QPS: {peak_qps}
- Data volume year 1 / year 3: <numbers>
- SLA target: {sla_target}
- RTO / RPO: <values>

## 5. Integration surface

- Identity provider: <e.g. Entra ID>
- Payment / billing: <if any>
- ERP / CRM: <if any>
- Email / SMS: <if any>
- Data warehouse: <if any>
- Legacy DBs to talk to: <list>

## 6. Deployment preferences

- Managed services vs. self-hosted: <preference>
- Preferred cloud: {deploy_pref}

## Unknowns

Any "TBD" answer above should also appear in `tech-debts.md` with
owner + priority.
