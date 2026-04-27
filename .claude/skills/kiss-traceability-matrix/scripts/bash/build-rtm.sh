#!/usr/bin/env bash
set -e
SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"
kiss_parse_standard_args "$@"
set -- "${KISS_REST_ARGS[@]}"

if [ "${1:-}" = "--help" ]; then
    cat <<'USAGE'
Usage: build-rtm.sh [--auto] [--answers FILE] [--dry-run] [--help]

Builds or updates the Requirements Traceability Matrix at
docs/analysis/traceability-matrix.md.

Answer keys: RTM_COVERAGE_THRESHOLD, RTM_INCLUDE_NFRS.
USAGE
    exit 0
fi

read_context

SKILL_DIR="$(CDPATH="" cd "$SCRIPT_DIR/../.." && pwd)"
ANALYSIS_DIR=$(worktype_dir "analysis")
OUT="$ANALYSIS_DIR/traceability-matrix.md"
DEBTS="$ANALYSIS_DIR/rtm-debts.md"
SRS="$KISS_REPO_ROOT/$KISS_DOCS_DIR/analysis/srs.md"

THRESHOLD=$(resolve_auto RTM_COVERAGE_THRESHOLD "80") || true
INCL_NFRS=$(resolve_auto RTM_INCLUDE_NFRS "true") || true

if [ ! -f "$SRS" ]; then
    echo "ERROR: srs.md not found at $SRS. Run /kiss.srs first." >&2
    exit 2
fi

# Count FR/NFR identifiers in SRS
TOTAL_FR=$(grep -cE 'FR-[0-9]+' "$SRS" 2>/dev/null || true)
TOTAL_NFR=0
if [ "$INCL_NFRS" = "true" ]; then
    TOTAL_NFR=$(grep -cE 'NFR-[0-9]+' "$SRS" 2>/dev/null || true)
fi
TOTAL=$((TOTAL_FR + TOTAL_NFR))

if [ "$TOTAL" -eq 0 ]; then
    append_debt "$DEBTS" RTMDEBT "SRS has no numbered FR/NFR entries — populate srs.md before building RTM" > /dev/null
    echo "WARNING: No FR/NFR identifiers found in $SRS. Wrote debt entry." >&2
fi

if [ "${KISS_DRY_RUN:-0}" = "1" ]; then
    echo "[dry-run] would write: $OUT"
    echo "  total_requirements=$TOTAL  threshold=${THRESHOLD}%"
    exit 0
fi

if ! confirm_before_write "Write RTM to $OUT ($TOTAL requirements detected)."; then
    echo "Aborted." >&2
    exit 1
fi

mkdir -p "$ANALYSIS_DIR"
PROJECT=$(basename "$KISS_REPO_ROOT")
DATE=$(date +%Y-%m-%d)
cp "$SKILL_DIR/templates/rtm-template.md" "$OUT"
sed -i.bak \
    -e "s|{project}|$PROJECT|g" \
    -e "s|{revision}|1.0|g" \
    -e "s|{date}|$DATE|g" \
    -e "s|{total}|$TOTAL|g" \
    -e "s|{rows}|<!-- AI: populate rows from SRS FR\/NFR scan -->|g" \
    "$OUT" && rm -f "$OUT.bak"

write_extract "$OUT" \
    "RTM_REVISION=1.0" \
    "TOTAL_REQS=$TOTAL" \
    "COVERAGE_PCT=0" \
    "UNCOVERED_REQS=$TOTAL" \
    "COVERAGE_THRESHOLD=$THRESHOLD" \
    "LAST_UPDATED=$DATE" > /dev/null

echo "Wrote $OUT (coverage data requires AI population of table rows)"
