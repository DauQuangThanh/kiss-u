#!/usr/bin/env bash
set -e
SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"
kiss_parse_standard_args "$@"
set -- "${KISS_REST_ARGS[@]}"

if [ "${1:-}" = "--help" ]; then
    cat <<'USAGE'
Usage: draft-handover.sh [--auto] [--answers FILE] [--dry-run] [--help]

Drafts the operations hand-over package for a feature or release.

Answer keys: HANDOVER_FEATURE, HANDOVER_RECEIVING_TEAM,
             HANDOVER_WARRANTY_DAYS, HANDOVER_ONCALL.
USAGE
    exit 0
fi

read_context

SKILL_DIR="$(CDPATH="" cd "$SCRIPT_DIR/../.." && pwd)"
DATE=$(date +%Y-%m-%d)

FEATURE=$(resolve_auto HANDOVER_FEATURE "${KISS_CURRENT_FEATURE:-}") || true
if [ -z "$FEATURE" ]; then
    echo "ERROR: HANDOVER_FEATURE is required." >&2
    exit 2
fi

RECEIVING=$(resolve_auto HANDOVER_RECEIVING_TEAM "internal-ops") || true
WARRANTY_DAYS=$(resolve_auto HANDOVER_WARRANTY_DAYS "30") || true
ONCALL=$(resolve_auto HANDOVER_ONCALL "business-hours") || true

# Compute warranty end date
WARRANTY_END=$(date -d "+${WARRANTY_DAYS} days" +%Y-%m-%d 2>/dev/null || \
               python3 -c "from datetime import date, timedelta; print((date.today() + timedelta(days=$WARRANTY_DAYS)).isoformat())" 2>/dev/null || \
               echo "TBD")

HANDOVER_DIR="$KISS_REPO_ROOT/$KISS_DOCS_DIR/operations/handover"
OUT="$HANDOVER_DIR/handover-package.md"
RUNBOOK_INDEX="$HANDOVER_DIR/runbook-index.md"
ESCALATION="$HANDOVER_DIR/support-escalation.md"
TRAINING="$HANDOVER_DIR/training-checklist.md"
DEBTS="$HANDOVER_DIR/handover-debts.md"

if [ "${KISS_DRY_RUN:-0}" = "1" ]; then
    echo "[dry-run] would write: $HANDOVER_DIR/"
    echo "  feature=$FEATURE  receiving=$RECEIVING  warranty_days=$WARRANTY_DAYS"
    exit 0
fi

if ! confirm_before_write "Write hand-over package to $HANDOVER_DIR/."; then
    echo "Aborted." >&2
    exit 1
fi

mkdir -p "$HANDOVER_DIR"
cp "$SKILL_DIR/templates/handover-package-template.md" "$OUT"

case "$ONCALL" in
    247)            ONCALL_MODEL="24/7 on-call" ;;
    business-hours) ONCALL_MODEL="Business hours (Mon–Fri)" ;;
    nbd)            ONCALL_MODEL="Next business day" ;;
    *)              ONCALL_MODEL="$ONCALL" ;;
esac

sed -i.bak \
    -e "s|{feature}|$FEATURE|g" \
    -e "s|{date}|$DATE|g" \
    -e "s|{go_live_date}|$DATE|g" \
    -e "s|{warranty_end}|$WARRANTY_END|g" \
    -e "s|{receiving_team}|$RECEIVING|g" \
    -e "s|{oncall_model}|$ONCALL_MODEL|g" \
    -e "s|{system_overview}|<!-- AI: populate from architecture and deployment artefacts -->|g" \
    -e "s|{runbook_rows}|<!-- AI: populate from deployment-strategy.md -->|g" \
    -e "s|{known_limitations}|<!-- AI: populate from risk-register and uat-sign-off waivers -->|g" \
    -e "s|{l1_sla}|4h|g" \
    -e "s|{l2_sla}|8h|g" \
    -e "s|{l3_sla}|2 business days|g" \
    -e "s|{l1_escalate_hrs}|4|g" \
    -e "s|{critical_response_sla}|2 hours|g" \
    -e "s|{rca_sla}|2|g" \
    "$OUT" && rm -f "$OUT.bak"

# Write companion files
cat > "$RUNBOOK_INDEX" <<EOF
# Runbook Index

**Feature:** $FEATURE
**Date:** $DATE

| Runbook | Scenario | Owner | Location | Last tested |
|---|---|---|---|---|
| Deployment runbook | Deploy / rollback | Ops team | docs/operations/deployment-strategy.md | *(TBD)* |
| Incident response | Unplanned outage | On-call | *(TBD)* | *(TBD)* |
| Data backup | DB backup / restore | Ops team | *(TBD)* | *(TBD)* |
EOF

cat > "$ESCALATION" <<EOF
# Support Escalation Matrix

**Feature:** $FEATURE

| Tier | Trigger | Team | Response SLA | Escalates to |
|---|---|---|---|---|
| L1 | User-reported; known issue | Support helpdesk | 4h | L2 after 4h |
| L2 | Unknown issue | Application team | 8h | L3 if code change needed |
| L3 | Code defect | Development team | 2 business days | Vendor if 3rd party |
| Vendor | 3rd-party failure | Vendor support | Per contract | — |
EOF

cat > "$TRAINING" <<EOF
# Knowledge Transfer Checklist

**Feature:** $FEATURE
**Target audience:** $RECEIVING

## Critical (complete before go-live)

- [ ] System architecture overview (30 min walkthrough)
- [ ] Deployment and rollback procedures (live demo)
- [ ] Alerting and monitoring dashboard (live demo)
- [ ] Escalation process and contacts

## Important (complete within first 2 weeks)

- [ ] Common support scenarios and resolutions
- [ ] Known limitations and workarounds
- [ ] Data backup and recovery procedures

## Reference (self-study)

- [ ] ADRs and design decisions
- [ ] API documentation
- [ ] Security considerations
EOF

write_extract "$OUT" \
    "HANDOVER_DATE=$DATE" \
    "WARRANTY_END=$WARRANTY_END" \
    "WARRANTY_DAYS=$WARRANTY_DAYS" \
    "ONCALL_MODEL=$ONCALL_MODEL" \
    "RECEIVING_TEAM=$RECEIVING" \
    "FEATURE=$FEATURE" > /dev/null

echo "Wrote $OUT"
echo "Wrote $RUNBOOK_INDEX"
echo "Wrote $ESCALATION"
echo "Wrote $TRAINING"
