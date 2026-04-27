# Operations Hand-Over Package: {feature}

**Date:** {date}
**Go-Live Date:** {go_live_date}
**Warranty / Hypercare End:** {warranty_end}
**Receiving Team:** {receiving_team}
**Status:** Draft — pending sign-off

---

## 1. System overview

{system_overview}

**Tech stack:** see `docs/architecture/` (ADRs, C4 diagrams)
**Deployment target:** see `docs/operations/deployment-strategy.md`
**Observability:** see `docs/operations/observability-plan.md`

---

## 2. Contacts and ownership

| Role | Name / Team | Contact | Notes |
|---|---|---|---|
| Delivery lead (handover from) | | | |
| Operations owner (handover to) | | | |
| On-call primary | | | |
| On-call secondary | | | |
| Vendor / cloud support | | | |

---

## 3. Runbook index

See `runbook-index.md` for the full catalogue.

| Runbook | Scenario | Owner | Location | Last tested |
|---|---|---|---|---|
| <!-- runbook name --> | <!-- scenario --> | <!-- owner --> | <!-- path --> | <!-- date --> |

---

## 4. Support escalation matrix

See `support-escalation.md` for full details.

| Tier | Trigger | Team | Response SLA | Escalates to |
|---|---|---|---|---|
| L1 | User-reported; known issue | Support helpdesk | {l1_sla} | L2 if unresolved in {l1_escalate_hrs}h |
| L2 | Unknown issue; application expertise needed | Application team | {l2_sla} | L3 if code change required |
| L3 | Code defect; architecture issue | Development team | {l3_sla} | Vendor if third-party |
| Vendor | Third-party component failure | Vendor support | Per SLA | — |

---

## 5. Warranty / hypercare period

**Hypercare start:** {go_live_date}
**Hypercare end:** {warranty_end}
**On-call model:** {oncall_model}

During hypercare, the development team provides:

- Response to Critical incidents within {critical_response_sla}
- Root-cause analysis for every P1/P2 incident within {rca_sla} business days
- Weekly health check report to the receiving team

---

## 6. Known limitations and deferred items

{known_limitations}

---

## 7. Training and knowledge transfer

See `training-checklist.md` for the full topic list and completion tracking.

---

## 8. Sign-off

| Role | Name | Signature | Date |
|---|---|---|---|
| Delivery Lead | | | |
| Operations Owner | | | |
| Business Sponsor | | | |

---

## Appendix: Open items (HOVRDEBT)

See `handover-debts.md`.
