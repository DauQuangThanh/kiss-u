#!/usr/bin/env bash
# kiss-status-report: scaffold a dated status report from template.

set -e

SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

kiss_parse_standard_args "$@"
set -- "${KISS_REST_ARGS[@]}"

if [ "${1:-}" = "--help" ]; then
    cat <<'USAGE'
Usage: draft-status.sh [--auto] [--answers FILE] [--dry-run] [--help]

Scaffolds docs/project/status-YYYY-MM-DD.md from the template. The AI
prompt fills in the sections using answers resolved from env / answers
file / upstream .extract files.
USAGE
    exit 0
fi

read_context

SKILL_DIR="$(CDPATH="" cd "$SCRIPT_DIR/../.." && pwd)"
PROJECT_DIR="$KISS_REPO_ROOT/$KISS_DOCS_DIR/project"
DEBTS_FILE="$PROJECT_DIR/pm-debts.md"

# Default the period to the last 7 days.
TODAY=$(date +%Y-%m-%d)
if date -u -d "7 days ago" +%Y-%m-%d >/dev/null 2>&1; then
    WEEK_AGO=$(date -u -d "7 days ago" +%Y-%m-%d)
else
    # BSD / macOS date
    WEEK_AGO=$(date -u -v-7d +%Y-%m-%d 2>/dev/null || echo "$TODAY")
fi

PERIOD_START=$(resolve_auto STATUS_PERIOD_START "$WEEK_AGO") || true
PERIOD_END=$(resolve_auto STATUS_PERIOD_END "$TODAY") || true
REPORT_DATE=$(resolve_auto STATUS_REPORT_DATE "$TODAY") || true
RAG=$(resolve_auto STATUS_RAG "") || rag_missing=1
BUDGET_VARIANCE=$(resolve_auto STATUS_BUDGET_VARIANCE "on-track") || true
ACCOMPLISHMENTS=$(resolve_auto STATUS_ACCOMPLISHMENTS "") || missing_acc=1
PLANNED=$(resolve_auto STATUS_PLANNED "") || missing_planned=1

# Auto-derive RAG from extracts if not set.
if [ -z "$RAG" ]; then
    RAG="green"
    if [ -f "$PROJECT_DIR/risk-register.extract" ]; then
        RED=$(grep -E '^RED=' "$PROJECT_DIR/risk-register.extract" | head -n1 | cut -d= -f2- || echo 0)
        AMBER=$(grep -E '^AMBER=' "$PROJECT_DIR/risk-register.extract" | head -n1 | cut -d= -f2- || echo 0)
        [ "${AMBER:-0}" -gt 0 ] && RAG="amber"
        [ "${RED:-0}" -gt 0 ] && RAG="red"
    fi
fi

case "$RAG" in
    red)   RAG_BAND="🔴 RED" ;;
    amber) RAG_BAND="🟡 AMBER" ;;
    *)     RAG_BAND="🟢 GREEN" ;;
esac

REPORT_FILE="$PROJECT_DIR/status-$REPORT_DATE.md"

if [ "${KISS_DRY_RUN:-0}" = "1" ]; then
    echo "[dry-run] would write: $REPORT_FILE"
    echo "[dry-run] period:       $PERIOD_START → $PERIOD_END"
    echo "[dry-run] rag:          $RAG_BAND"
    echo "[dry-run] budget:       $BUDGET_VARIANCE"
    echo "[dry-run] accomplishm.: ${ACCOMPLISHMENTS:-<missing>}"
    echo "[dry-run] planned:      ${PLANNED:-<missing>}"
    exit 0
fi

if [ -f "$REPORT_FILE" ]; then
    echo "Status report for $REPORT_DATE already exists: $REPORT_FILE" >&2
    echo "Edit in place or pick a different STATUS_REPORT_DATE." >&2
    exit 2
fi

if ! confirm_before_write "Scaffold status report at $REPORT_FILE."; then
    echo "Aborted." >&2
    exit 1
fi

mkdir -p "$PROJECT_DIR"

# Derive project name from project-plan extract if present.
PROJECT_NAME="${KISS_CURRENT_FEATURE:-project}"
if [ -f "$PROJECT_DIR/project-plan.extract" ]; then
    _p=$(grep -E '^PROJECT_NAME=' "$PROJECT_DIR/project-plan.extract" | head -n1 | cut -d= -f2-)
    [ -n "$_p" ] && PROJECT_NAME="$_p"
fi

TEMPLATE="$SKILL_DIR/templates/status-report-template.md"
sed \
    -e "s|{project_name}|$PROJECT_NAME|g" \
    -e "s|{feature}|${KISS_CURRENT_FEATURE:-<none>}|g" \
    -e "s|{period_start}|$PERIOD_START|g" \
    -e "s|{period_end}|$PERIOD_END|g" \
    -e "s|{report_date}|$REPORT_DATE|g" \
    -e "s|{rag_band}|$RAG_BAND|g" \
    -e "s|{budget_variance}|$BUDGET_VARIANCE|g" \
    "$TEMPLATE" > "$REPORT_FILE"

write_extract "$REPORT_FILE" \
    "REPORT_DATE=$REPORT_DATE" \
    "PERIOD_START=$PERIOD_START" \
    "PERIOD_END=$PERIOD_END" \
    "RAG=$RAG" \
    "BUDGET_VARIANCE=$BUDGET_VARIANCE" > /dev/null

echo "Wrote $REPORT_FILE"

# Debts
if [ -n "${rag_missing:-}" ]; then
    append_debt "$DEBTS_FILE" PMDEBT "Status RAG auto-computed to $RAG — user must confirm in $REPORT_FILE (Area: Quality, Priority: 🟡 Important)" > /dev/null
fi
if [ -n "${missing_acc:-}" ]; then
    append_debt "$DEBTS_FILE" PMDEBT "Status report for $REPORT_DATE has no accomplishments recorded (Area: Comms, Priority: 🟢 Can wait)" > /dev/null
fi
if [ -n "${missing_planned:-}" ]; then
    append_debt "$DEBTS_FILE" PMDEBT "Status report for $REPORT_DATE has no planned activities for next period (Area: Schedule, Priority: 🟡 Important)" > /dev/null
fi
