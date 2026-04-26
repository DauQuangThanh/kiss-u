#!/usr/bin/env bash
# kiss-change-control: append one change-request entry to the change log.

set -e

SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

kiss_parse_standard_args "$@"
set -- "${KISS_REST_ARGS[@]}"

if [ "${1:-}" = "--help" ]; then
    cat <<'USAGE'
Usage: add-change.sh [--auto] [--answers FILE] [--dry-run] [--help]

Appends one change-request entry to docs/project/change-log.md.
See kiss-change-control.md for answer keys.
USAGE
    exit 0
fi

read_context

SKILL_DIR="$(CDPATH="" cd "$SCRIPT_DIR/../.." && pwd)"
PROJECT_DIR="$KISS_REPO_ROOT/$KISS_DOCS_DIR/project"
LOG="$PROJECT_DIR/change-log.md"
DEBTS_FILE="$PROJECT_DIR/pm-debts.md"

DESCRIPTION=$(resolve_auto CR_DESCRIPTION "") || missing_desc=1
REQUESTER=$(resolve_auto CR_REQUESTER "") || missing_requester=1
REASON=$(resolve_auto CR_REASON "") || true
SOLUTION=$(resolve_auto CR_PROPOSED_SOLUTION "") || true
SCOPE_IMPACT=$(resolve_auto CR_SCOPE_IMPACT "L") || true
SCHEDULE_IMPACT=$(resolve_auto CR_SCHEDULE_IMPACT "L") || true
BUDGET_IMPACT=$(resolve_auto CR_BUDGET_IMPACT "L") || true
QUALITY_IMPACT=$(resolve_auto CR_QUALITY_IMPACT "L") || true
PRIORITY=$(resolve_auto CR_PRIORITY "🟢 Medium") || true
STATUS=$(resolve_auto CR_STATUS "Pending") || true
APPROVED_BY=$(resolve_auto CR_APPROVED_BY "") || true
DECISION_DATE=$(resolve_auto CR_DECISION_DATE "") || true
DECISION_REASON=$(resolve_auto CR_DECISION_REASON "") || true

# Validate H/M/L
for var in SCOPE_IMPACT SCHEDULE_IMPACT BUDGET_IMPACT QUALITY_IMPACT; do
    val="${!var}"
    case "$val" in H|M|L) ;; *) printf -v "$var" 'L' ;; esac
done

# Validate status
case "$STATUS" in
    Pending|Approved|Rejected|"On Hold"|Closed) ;;
    *) STATUS="Pending" ;;
esac

if [ "${KISS_DRY_RUN:-0}" = "1" ]; then
    echo "[dry-run] would append CR to: $LOG"
    echo "[dry-run] description:   ${DESCRIPTION:-<missing>}"
    echo "[dry-run] requester:     ${REQUESTER:-<missing>}"
    echo "[dry-run] priority:      $PRIORITY"
    echo "[dry-run] impact S/S/B/Q: $SCOPE_IMPACT/$SCHEDULE_IMPACT/$BUDGET_IMPACT/$QUALITY_IMPACT"
    echo "[dry-run] status:        $STATUS"
    exit 0
fi

if ! confirm_before_write "Append change-request to $LOG."; then
    echo "Aborted." >&2
    exit 1
fi

mkdir -p "$PROJECT_DIR"

# Bootstrap the log from template on first use.
if [ ! -f "$LOG" ]; then
    TEMPLATE="$SKILL_DIR/templates/change-log-template.md"
    PROJECT_NAME="${KISS_CURRENT_FEATURE:-project}"
    if [ -f "$PROJECT_DIR/project-plan.extract" ]; then
        _p=$(grep -E '^PROJECT_NAME=' "$PROJECT_DIR/project-plan.extract" | head -n1 | cut -d= -f2-)
        [ -n "$_p" ] && PROJECT_NAME="$_p"
    fi
    sed \
        -e "s|{project_name}|$PROJECT_NAME|g" \
        -e "s|{date}|$(date +%Y-%m-%d)|g" \
        -e "s|{feature}|${KISS_CURRENT_FEATURE:-<none>}|g" \
        "$TEMPLATE" > "$LOG"
    # Strip the placeholder CR-NN block.
    awk 'BEGIN{skip=0} /^### CR-NN:/{skip=1} skip && /^---$/{skip=0; next} !skip' "$LOG" > "$LOG.tmp"
    mv "$LOG.tmp" "$LOG"
fi

# Next id
NEXT=1
last=$(grep -Eo '^### CR-[0-9]+' "$LOG" 2>/dev/null | grep -Eo '[0-9]+$' | sort -n | tail -n1 || true)
if [ -n "$last" ]; then NEXT=$((10#$last + 1)); fi
CR_ID=$(printf 'CR-%02d' "$NEXT")
REQUEST_DATE=$(date +%Y-%m-%d)

{
    printf '\n### %s: %s\n\n' "$CR_ID" "${DESCRIPTION:-<TBD>}"
    printf '**Requested by:** %s\n' "${REQUESTER:-<TBD>}"
    printf '**Request date:** %s\n' "$REQUEST_DATE"
    printf '**Priority:** %s\n' "$PRIORITY"
    printf '**Status:** %s\n\n' "$STATUS"
    printf '**Scope impact:** %s\n' "$SCOPE_IMPACT"
    printf '**Schedule impact:** %s\n' "$SCHEDULE_IMPACT"
    printf '**Budget impact:** %s\n' "$BUDGET_IMPACT"
    printf '**Quality impact:** %s\n\n' "$QUALITY_IMPACT"
    printf '**Reason for request:** %s\n' "${REASON:-<TBD>}"
    printf '**Proposed solution:** %s\n\n' "${SOLUTION:-<TBD>}"
    printf '**Decision:** %s\n' "$STATUS"
    printf '**Decision date:** %s\n' "${DECISION_DATE:-TBD}"
    printf '**Decided by:** %s\n' "${APPROVED_BY:-TBD}"
    printf '**Decision reason:** %s\n\n' "${DECISION_REASON:-<TBD>}"
    if [ "$STATUS" = "Approved" ]; then
        printf '**Implementation plan:**\n\n'
        printf '1. <step 1>\n2. <step 2>\n3. <step 3>\n\n'
    fi
    printf '**Completion date:** TBD\n\n---\n'
} >> "$LOG"

# Extract: count by status.
TOTAL=$(grep -c '^### CR-' "$LOG" 2>/dev/null)     || true
PENDING=$(grep -cE '^\*\*Status:\*\* Pending' "$LOG" 2>/dev/null)   || true
APPROVED=$(grep -cE '^\*\*Status:\*\* Approved' "$LOG" 2>/dev/null) || true
REJECTED=$(grep -cE '^\*\*Status:\*\* Rejected' "$LOG" 2>/dev/null) || true
TOTAL=${TOTAL:-0}; PENDING=${PENDING:-0}; APPROVED=${APPROVED:-0}; REJECTED=${REJECTED:-0}

write_extract "$LOG" \
    "TOTAL_CRS=$TOTAL" \
    "PENDING=$PENDING" \
    "APPROVED=$APPROVED" \
    "REJECTED=$REJECTED" \
    "LAST_ADDED=$CR_ID" > /dev/null

echo "Appended $CR_ID ($STATUS, $PRIORITY) to $LOG"

# Debts
if [ -n "${missing_desc:-}" ]; then
    append_debt "$DEBTS_FILE" PMDEBT "CR $CR_ID has no description (Area: Scope, Owner: user, Priority: 🔴 Blocking)" > /dev/null
fi
if [ -n "${missing_requester:-}" ]; then
    append_debt "$DEBTS_FILE" PMDEBT "CR $CR_ID has no requester recorded (Area: Scope, Owner: user, Priority: 🟡 Important)" > /dev/null
fi
if [ "$STATUS" = "Approved" ] && [ -z "$APPROVED_BY" ]; then
    append_debt "$DEBTS_FILE" PMDEBT "CR $CR_ID marked Approved but has no approver on record (Area: Governance, Owner: user, Priority: 🟡 Important)" > /dev/null
fi
