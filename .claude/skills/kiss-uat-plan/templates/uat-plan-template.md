# UAT Plan: {feature}

**Revision:** {revision}
**Date:** {date}
**Feature / Release:** {feature}
**UAT Environment:** {uat_env}
**UAT Window:** {start_date} → {end_date}
**Status:** Draft

---

## 1. Scope

### In scope

{in_scope}

### Out of scope

{out_scope}

---

## 2. Participants and roles

| Role | Responsibilities | Count |
|---|---|---|
| Business Sponsor | Final sign-off authority; approves pass/fail | 1 |
| UAT Coordinator | Schedules sessions, collects results, liaises with dev | 1 |
| End-User Representatives | Execute UAT scenarios; provide feedback | {user_rep_count} |
| Subject Matter Experts | Answer domain questions; validate edge cases | {sme_count} |
| Development Support | On standby to fix blockers; no scenario execution | 1–2 |

---

## 3. UAT environment

| Item | Detail |
|---|---|
| Environment | {uat_env} |
| URL / access method | *(to be populated)* |
| Test data policy | {test_data_policy} |
| Data refresh cadence | {data_refresh} |
| Environment owner | *(to be populated)* |

---

## 4. Entry criteria

All of the following must be satisfied before UAT begins:

- [ ] System testing complete (no open Critical or High bugs)
- [ ] UAT environment provisioned and smoke-tested
- [ ] Test data loaded and validated
- [ ] UAT participants briefed (roles, objectives, tools)
- [ ] Sign-off ledger distributed to Business Sponsor
- [ ] Defect management channel established

---

## 5. UAT scenarios

<!-- Each scenario is a business-workflow description, not a technical
     test script. Steps should be written for a non-technical user.
     Link to the acceptance criterion it validates (AC ref). -->

{scenarios}

---

## 6. Defect management

| Severity | Definition | Response SLA | Sign-off impact |
|---|---|---|---|
| Critical | Core business workflow broken; no workaround | Fix within 1 business day | Blocks sign-off |
| High | Significant issue; workaround exists | Fix before end of UAT | Blocks sign-off if >{high_threshold} open |
| Medium | Minor impact; workaround available | Log; fix in next sprint | Does not block sign-off |
| Low | Cosmetic or enhancement | Backlog | Does not block sign-off |

---

## 7. Exit criteria

UAT is considered complete when ALL of the following are met:

- [ ] All Critical UAT scenarios executed
- [ ] Zero open Critical defects
- [ ] Open High defects ≤ {high_threshold}
- [ ] Business Sponsor has reviewed the execution summary
- [ ] uat-sign-off.md signed by Business Sponsor

---

## 8. Schedule

| Activity | Date | Owner |
|---|---|---|
| Environment readiness check | | UAT Coordinator |
| UAT kick-off briefing | {start_date} | UAT Coordinator |
| Scenario execution | {start_date} → {end_date} | End-User Reps |
| Defect fix window | | Development Support |
| Re-test of fixed defects | | End-User Reps |
| Sign-off meeting | {end_date} | Business Sponsor |

---

## 9. Open items (UATDEBT)

See `uat-debts.md`.
