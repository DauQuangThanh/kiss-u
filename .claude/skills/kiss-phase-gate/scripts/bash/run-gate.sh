#!/usr/bin/env bash
set -e
SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"
kiss_parse_standard_args "$@"
set -- "${KISS_REST_ARGS[@]}"

if [ "${1:-}" = "--help" ]; then
    cat <<'USAGE'
Usage: run-gate.sh [--auto] [--answers FILE] [--dry-run] [--help]

Creates a phase-gate record at docs/project/gates/GATE-<type>-<date>.md.

Answer keys: GATE_TYPE, GATE_DATE, GATE_COVERAGE_THRESHOLD.
Valid gate types: requirements | architecture | ttr | orr | go-live
USAGE
    exit 0
fi

read_context

SKILL_DIR="$(CDPATH="" cd "$SCRIPT_DIR/../.." && pwd)"
GATES_DIR="$KISS_REPO_ROOT/$KISS_DOCS_DIR/project/gates"
DEBTS="$GATES_DIR/gate-debts.md"

GATE_TYPE=$(resolve_auto GATE_TYPE "") || true
GATE_DATE=$(resolve_auto GATE_DATE "$(date +%Y-%m-%d)") || true
THRESHOLD=$(resolve_auto GATE_COVERAGE_THRESHOLD "80") || true

# Validate gate type
case "$GATE_TYPE" in
    requirements|architecture|ttr|orr|go-live) ;;
    "")
        echo "ERROR: GATE_TYPE is required. Valid values: requirements | architecture | ttr | orr | go-live" >&2
        exit 2
        ;;
    *)
        echo "ERROR: Unknown GATE_TYPE '$GATE_TYPE'. Valid: requirements | architecture | ttr | orr | go-live" >&2
        exit 2
        ;;
esac

# Gate labels
case "$GATE_TYPE" in
    requirements) GATE_LABEL="System Requirements Review (SRR)" ;;
    architecture) GATE_LABEL="Critical Design Review (CDR)" ;;
    ttr)          GATE_LABEL="Test Readiness Review (TRR)" ;;
    orr)          GATE_LABEL="Operational Readiness Review (ORR)" ;;
    go-live)      GATE_LABEL="Go/No-Go Review" ;;
esac

OUT="$GATES_DIR/GATE-${GATE_TYPE}-${GATE_DATE}.md"

if [ "${KISS_DRY_RUN:-0}" = "1" ]; then
    echo "[dry-run] would write: $OUT"
    echo "  gate_type=$GATE_TYPE  date=$GATE_DATE  threshold=${THRESHOLD}%"
    exit 0
fi

if ! confirm_before_write "Write gate record to $OUT."; then
    echo "Aborted." >&2
    exit 1
fi

mkdir -p "$GATES_DIR"
PROJECT=$(basename "$KISS_REPO_ROOT")

cp "$SKILL_DIR/templates/gate-template.md" "$OUT"
sed -i.bak \
    -e "s|{gate_label}|$GATE_LABEL|g" \
    -e "s|{gate_type}|$GATE_TYPE|g" \
    -e "s|{project}|$PROJECT|g" \
    -e "s|{date}|$GATE_DATE|g" \
    -e "s|{deliverables}|<!-- AI: populate from upstream artefact scan -->|g" \
    -e "s|{entry_criteria}|<!-- AI: populate for $GATE_TYPE gate -->|g" \
    -e "s|{exit_criteria}|<!-- AI: populate for $GATE_TYPE gate -->|g" \
    -e "s|{risks}|<!-- AI: populate from risk-register.md -->|g" \
    -e "s|{blockers}|<!-- AI: populate from gate-debts.md -->|g" \
    -e "s|{waivers}|<!-- None documented yet -->|g" \
    -e "s|{recommendation}|Pending review|g" \
    -e "s|{recommendation_detail}|<!-- AI: add recommendation after criteria evaluation -->|g" \
    "$OUT" && rm -f "$OUT.bak"

write_extract "$OUT" \
    "GATE_TYPE=$GATE_TYPE" \
    "GATE_LABEL=$GATE_LABEL" \
    "GATE_DATE=$GATE_DATE" \
    "GATE_OUTCOME=Pending" \
    "OPEN_BLOCKERS=0" \
    "COVERAGE_THRESHOLD=$THRESHOLD" > /dev/null

echo "Wrote $OUT"
echo "Next: AI evaluates criteria and populates the gate record, then stakeholders sign off"
