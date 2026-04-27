# Data Migration Plan: {project}

**Revision:** {revision}
**Date:** {date}
**Migration Strategy:** {strategy}
**Cutover Window:** {cutover_window}
**Status:** Draft

---

## 1. Migration overview

| Item | Value |
|---|---|
| Source system | {source_system} |
| Target system | {target_system} |
| Migration strategy | {strategy} |
| Estimated record volume | {record_volume} |
| Contains PII | {has_pii} |
| Estimated migration duration | {duration_estimate} |

---

## 2. Scope

### In scope

{in_scope}

### Out of scope (deferred or excluded data)

{out_scope}

---

## 3. Migration strategy rationale

**Selected strategy:** {strategy}

{strategy_rationale}

---

## 4. Data quality rules

| Rule | Description | Action on violation |
|---|---|---|
| Null handling | Required fields with null source values | {null_action} |
| Deduplication | Records matching on {dedup_key} | Retain most recent; log discarded |
| Encoding | All text fields must be UTF-8 | Transcode at extract; reject non-transcodable |
| Date normalisation | All dates stored as ISO 8601 UTC | Apply timezone offset at transform |
| Referential integrity | Foreign key references must resolve | Log orphans as DMDEBT; set to null / sentinel |

---

## 5. ETL outline

### 5.1 Extract

- **Mechanism:** {extract_mechanism}
- **Mode:** {extract_mode} (full / incremental)
- **Batch size:** {batch_size} records per batch

### 5.2 Transform

{transform_rules}

### 5.3 Load

- **Load mode:** upsert (insert or update on primary key)
- **Idempotency key:** {idempotency_key}
- **Index strategy:** disable non-unique indexes during bulk load; rebuild after

### 5.4 Verify

- Record count in target matches source (±0.01%)
- Spot-check 100 randomly selected records per entity
- Checksum / hash comparison on critical fields
- Referential integrity queries pass

---

## 6. Cutover plan

| Step | Description | Owner | Go/No-Go checkpoint |
|---|---|---|---|
| T-7 days | Dry-run migration on staging; document results | Migration lead | Record count match ≥ 99.9% |
| T-3 days | Resolve all dry-run DMDEBT items | Dev team | All blockers closed |
| T-1 day | Final data quality snapshot of source | Migration lead | Quality score baseline |
| Cutover start | Freeze writes to source system | PM | Stakeholders notified |
| Migrate | Execute ETL; monitor progress | Migration lead | Error rate < threshold |
| Verify | Run reconciliation checks | QA | All checks pass |
| Go/No-Go | Decision to proceed or roll back | PM + Tech Lead | See rollback trigger |
| Cutover end | Open writes to target system | PM | Go confirmed |
| T+24 hours | Post-migration validation checklist | QA | All items checked |

### Rollback trigger

**Condition:** {rollback_trigger}

### Rollback procedure

1. Stop all load processes immediately.
2. Re-enable writes to the source system.
3. Notify stakeholders and document the failure point.
4. Restore target database to pre-migration snapshot (if applicable).
5. Run post-rollback verification on source system integrity.
6. Schedule retrospective within 24 hours.

---

## 7. Post-migration validation checklist

- [ ] Record counts match within tolerance (±0.01%)
- [ ] All critical entity spot-checks pass
- [ ] No unresolved referential integrity violations
- [ ] Application smoke test passes in production
- [ ] Monitoring alerts baseline re-established
- [ ] Source system decommission plan confirmed (if applicable)
- [ ] Migration log archived and accessible

---

## 8. Privacy and compliance

{privacy_notes}

---

## 9. Open items (DMDEBT)

See `dm-debts.md`.
