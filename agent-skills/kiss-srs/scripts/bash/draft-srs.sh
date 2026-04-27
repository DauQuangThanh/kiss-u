#!/usr/bin/env bash
set -e
SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"
kiss_parse_standard_args "$@"
set -- "${KISS_REST_ARGS[@]}"

if [ "${1:-}" = "--help" ]; then
    cat <<'USAGE'
Usage: draft-srs.sh [--auto] [--answers FILE] [--dry-run] [--help]

Aggregates all feature specs into a consolidated SRS document at
docs/architecture/srs.md. Numbers every FR and NFR.

Answer keys: SRS_TITLE, SRS_REVISION, SRS_AUDIENCE,
             SRS_INCLUDE_TRACE_STUB.
USAGE
    exit 0
fi

read_context

SKILL_DIR="$(CDPATH="" cd "$SCRIPT_DIR/../.." && pwd)"
ARCH_DIR=$(worktype_dir "architecture")
OUT="$ARCH_DIR/srs.md"
DEBTS="$ARCH_DIR/srs-debts.md"

# Resolve answer keys
PROJECT=$(resolve_auto SRS_PROJECT "$(basename "$KISS_REPO_ROOT")") || true
TITLE=$(resolve_auto SRS_TITLE "${PROJECT} Software Requirements Specification") || true
REVISION=$(resolve_auto SRS_REVISION "1.0") || true
AUDIENCE=$(resolve_auto SRS_AUDIENCE "internal") || true
INCLUDE_TRACE=$(resolve_auto SRS_INCLUDE_TRACE_STUB "true") || true

# Validate audience value
case "$AUDIENCE" in internal|external|regulatory|all) ;; *)
    AUDIENCE="internal"
    write_decision "default-applied" "SRS_AUDIENCE set to 'internal'" "invalid value provided" || true
    ;;
esac

if [ "${KISS_DRY_RUN:-0}" = "1" ]; then
    echo "[dry-run] would write: $OUT"
    echo "  title=$TITLE  revision=$REVISION  audience=$AUDIENCE"
    exit 0
fi

# Discover spec files
SPEC_COUNT=0
if [ -d "$KISS_REPO_ROOT/$KISS_SPECS_DIR" ]; then
    SPEC_COUNT=$(find "$KISS_REPO_ROOT/$KISS_SPECS_DIR" -name "spec.md" 2>/dev/null | wc -l | tr -d ' ')
fi
if [ "$SPEC_COUNT" -eq 0 ]; then
    echo "ERROR: No spec.md files found under $KISS_SPECS_DIR. Run /kiss.specify for each feature first." >&2
    exit 2
fi

if ! confirm_before_write "Write SRS to $OUT (aggregating $SPEC_COUNT spec(s))."; then
    echo "Aborted." >&2
    exit 1
fi

mkdir -p "$ARCH_DIR"
cp "$SKILL_DIR/templates/srs-template.md" "$OUT"

DATE=$(date +%Y-%m-%d)
# Replace simple placeholders
sed -i.bak \
    -e "s|{title}|$TITLE|g" \
    -e "s|{project}|$PROJECT|g" \
    -e "s|{revision}|$REVISION|g" \
    -e "s|{date}|$DATE|g" \
    "$OUT" && rm -f "$OUT.bak"

write_extract "$OUT" \
    "SRS_REVISION=$REVISION" \
    "SRS_TITLE=$TITLE" \
    "SRS_AUDIENCE=$AUDIENCE" \
    "BASELINE_DATE=$DATE" \
    "SPEC_COUNT=$SPEC_COUNT" > /dev/null

echo "Wrote $OUT"
echo "Next: populate FR/NFR sections from spec files, then run /kiss.traceability-matrix"
