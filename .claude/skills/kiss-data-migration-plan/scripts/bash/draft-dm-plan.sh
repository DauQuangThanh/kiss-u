#!/usr/bin/env bash
set -e
SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"
kiss_parse_standard_args "$@"
set -- "${KISS_REST_ARGS[@]}"

if [ "${1:-}" = "--help" ]; then
    cat <<'USAGE'
Usage: draft-dm-plan.sh [--auto] [--answers FILE] [--dry-run] [--help]

Drafts the data migration plan, field mapping, and cutover runbook.

Answer keys: DM_STRATEGY, DM_SOURCE, DM_RECORD_VOLUME,
             DM_CUTOVER_WINDOW, DM_ROLLBACK_TRIGGER, DM_HAS_PII.
Valid strategies: big-bang | phased | parallel | trickle
USAGE
    exit 0
fi

read_context

SKILL_DIR="$(CDPATH="" cd "$SCRIPT_DIR/../.." && pwd)"
DATE=$(date +%Y-%m-%d)

STRATEGY=$(resolve_auto DM_STRATEGY "big-bang") || true
SOURCE=$(resolve_auto DM_SOURCE "Legacy system") || true
VOLUME=$(resolve_auto DM_RECORD_VOLUME "Unknown") || true
CUTOVER=$(resolve_auto DM_CUTOVER_WINDOW "TBD") || true
ROLLBACK_TRIGGER=$(resolve_auto DM_ROLLBACK_TRIGGER "any-failure") || true
HAS_PII=$(resolve_auto DM_HAS_PII "false") || true

case "$STRATEGY" in big-bang|phased|parallel|trickle) ;; *)
    echo "WARNING: Unknown DM_STRATEGY '$STRATEGY'. Defaulting to 'big-bang'." >&2
    STRATEGY="big-bang"
    write_decision "default-applied" "DM_STRATEGY set to 'big-bang'" "invalid value provided" || true
    ;;
esac

OPS_DIR=$(worktype_dir "operations")
OUT="$OPS_DIR/data-migration-plan.md"
FIELD_MAP="$OPS_DIR/field-mapping.md"
RUNBOOK="$OPS_DIR/migration-runbook.md"
DEBTS="$OPS_DIR/dm-debts.md"

if [ "${KISS_DRY_RUN:-0}" = "1" ]; then
    echo "[dry-run] would write: $OPS_DIR/data-migration-plan.md"
    echo "  strategy=$STRATEGY  source=$SOURCE  volume=$VOLUME  pii=$HAS_PII"
    exit 0
fi

if ! confirm_before_write "Write data migration plan to $OPS_DIR/."; then
    echo "Aborted." >&2
    exit 1
fi

mkdir -p "$OPS_DIR"
PROJECT=$(basename "$KISS_REPO_ROOT")

# Strategy rationale
case "$STRATEGY" in
    big-bang)  RATIONALE="All data moved in a single cutover window. Simpler coordination but requires planned downtime." ;;
    phased)    RATIONALE="Data migrated in batches by domain or date range, allowing partial go-live and risk reduction." ;;
    parallel)  RATIONALE="Old and new systems run simultaneously with data kept in sync, enabling near-zero downtime cutover." ;;
    trickle)   RATIONALE="Continuous replication via Change Data Capture until the final cutover, minimising downtime for very large datasets." ;;
esac

# Rollback trigger
case "$ROLLBACK_TRIGGER" in
    any-failure) ROLLBACK_TEXT="Any reconciliation check fails (zero-tolerance)" ;;
    threshold)   ROLLBACK_TEXT="Error rate exceeds 0.1% of total records" ;;
    manual)      ROLLBACK_TEXT="Manual decision by PM and Tech Lead at Go/No-Go checkpoint" ;;
    *)           ROLLBACK_TEXT="$ROLLBACK_TRIGGER" ;;
esac

# Privacy note
if [ "$HAS_PII" = "true" ]; then
    PRIVACY="- All PII fields must be encrypted in transit (TLS 1.2+) and at rest (AES-256).\n- Access to migration tooling is restricted to named team members only.\n- Audit log of all data access during migration is mandatory.\n- GDPR / applicable data protection obligations apply to the migrated data."
else
    PRIVACY="No PII identified in migration scope. If this assessment changes, update this section and raise a DMDEBT entry for compliance review."
fi

cp "$SKILL_DIR/templates/dm-plan-template.md" "$OUT"
sed -i.bak \
    -e "s|{project}|$PROJECT|g" \
    -e "s|{revision}|1.0|g" \
    -e "s|{date}|$DATE|g" \
    -e "s|{strategy}|$STRATEGY|g" \
    -e "s|{cutover_window}|$CUTOVER|g" \
    -e "s|{source_system}|$SOURCE|g" \
    -e "s|{target_system}|$PROJECT (new)|g" \
    -e "s|{record_volume}|$VOLUME|g" \
    -e "s|{has_pii}|$HAS_PII|g" \
    -e "s|{duration_estimate}|TBD (based on volume and strategy)|g" \
    -e "s|{strategy_rationale}|$RATIONALE|g" \
    -e "s|{rollback_trigger}|$ROLLBACK_TEXT|g" \
    -e "s|{null_action}|Set to field default or log DMDEBT|g" \
    -e "s|{dedup_key}|primary business key|g" \
    -e "s|{extract_mechanism}|TBD — specify DB export method or API|g" \
    -e "s|{extract_mode}|full|g" \
    -e "s|{batch_size}|10,000|g" \
    -e "s|{transform_rules}|<!-- AI: populate from field-mapping.md -->|g" \
    -e "s|{idempotency_key}|business_id|g" \
    -e "s|{in_scope}|<!-- AI: populate from SRS and design documents -->|g" \
    -e "s|{out_scope}|<!-- AI: populate from SRS out-of-scope -->|g" \
    "$OUT" && rm -f "$OUT.bak"

# Fix multiline privacy section
printf '%s\n' "$PRIVACY" >> "$OUT"

# Field mapping
cp "$SKILL_DIR/templates/field-mapping-template.md" "$FIELD_MAP"
sed -i.bak \
    -e "s|{project}|$PROJECT|g" \
    -e "s|{date}|$DATE|g" \
    -e "s|{strategy}|$STRATEGY|g" \
    -e "s|{mapping_sections}|<!-- AI: populate one section per target entity from design data model -->|g" \
    -e "s|{unmapped_rows}|<!-- AI: list fields with no source mapping -->|g" \
    "$FIELD_MAP" && rm -f "$FIELD_MAP.bak"

# Runbook (lightweight scaffold)
cat > "$RUNBOOK" <<EOF
# Migration Cutover Runbook: $PROJECT

**Strategy:** $STRATEGY
**Cutover window:** $CUTOVER
**Rollback trigger:** $ROLLBACK_TEXT

## Pre-cutover checklist (T-1 day)

- [ ] Dry-run results reviewed and approved
- [ ] All DMDEBT blockers resolved
- [ ] Stakeholders notified of maintenance window
- [ ] Rollback environment (source DB snapshot) confirmed

## Cutover steps

<!-- AI: expand steps from dm-plan-template.md cutover plan -->

## Post-cutover validation

See Section 7 of data-migration-plan.md.
EOF

write_extract "$OUT" \
    "DM_STRATEGY=$STRATEGY" \
    "DM_SOURCE=$SOURCE" \
    "DM_RECORD_VOLUME=$VOLUME" \
    "DM_CUTOVER_WINDOW=$CUTOVER" \
    "DM_ROLLBACK_TRIGGER=$ROLLBACK_TRIGGER" \
    "DM_HAS_PII=$HAS_PII" \
    "DM_PLAN_DATE=$DATE" > /dev/null

echo "Wrote $OUT"
echo "Wrote $FIELD_MAP"
echo "Wrote $RUNBOOK"
