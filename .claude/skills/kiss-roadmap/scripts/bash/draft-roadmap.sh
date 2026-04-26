#!/usr/bin/env bash
# kiss-roadmap: scaffold docs/product/roadmap.md from the roadmap template.
set -e
SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"
kiss_parse_standard_args "$@"
set -- "${KISS_REST_ARGS[@]}"

if [ "${1:-}" = "--help" ]; then
    cat <<'USAGE'
Usage: draft-roadmap.sh [--auto] [--answers FILE] [--dry-run] [--help]
Scaffolds docs/product/roadmap.md. The agent fills the Now/Next/Later tables
by reading docs/product/backlog.md and proposing windows.
USAGE
    exit 0
fi

read_context
SKILL_DIR="$(CDPATH="" cd "$SCRIPT_DIR/../.." && pwd)"
DIR="$KISS_REPO_ROOT/$KISS_DOCS_DIR/product"
OUT="$DIR/roadmap.md"

STYLE=$(resolve_auto RM_WINDOW_STYLE "nnl") || true
NOW_WEEKS=$(resolve_auto RM_NOW_WEEKS "4") || true
NEXT_WEEKS=$(resolve_auto RM_NEXT_WEEKS "12") || true

if [ "$STYLE" = "date" ]; then
    NOW_RANGE="next $NOW_WEEKS weeks"
    NEXT_RANGE="weeks $((NOW_WEEKS + 1))–$((NOW_WEEKS + NEXT_WEEKS))"
else
    NOW_RANGE="in flight"
    NEXT_RANGE="up next"
fi

if [ "${KISS_DRY_RUN:-0}" = "1" ]; then
    echo "[dry-run] would write: $OUT"
    echo "[dry-run] style: $STYLE  now: $NOW_RANGE  next: $NEXT_RANGE"
    exit 0
fi

if ! confirm_before_write "Scaffold roadmap at $OUT."; then echo "Aborted." >&2; exit 1; fi

mkdir -p "$DIR"
if [ -f "$OUT" ]; then
    echo "Roadmap already exists: $OUT (edit in place)." >&2; exit 2
fi

sed \
    -e "s|{date}|$(date +%Y-%m-%d)|g" \
    -e "s|{window_style}|$STYLE|g" \
    -e "s|{now_range}|$NOW_RANGE|g" \
    -e "s|{next_range}|$NEXT_RANGE|g" \
    "$SKILL_DIR/templates/roadmap-template.md" > "$OUT"

write_extract "$OUT" "STYLE=$STYLE" "NOW_RANGE=$NOW_RANGE" "NEXT_RANGE=$NEXT_RANGE" > /dev/null
echo "Wrote $OUT"
