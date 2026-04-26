#!/usr/bin/env bash
set -e
SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"
kiss_parse_standard_args "$@"
set -- "${KISS_REST_ARGS[@]}"
if [ "${1:-}" = "--help" ]; then
    echo "Usage: review.sh [--auto]. Keys: QR_SCOPE, QR_MAX_CYCLOMATIC, QR_MAX_FUNCTION_LINES."; exit 0
fi
read_context
SKILL_DIR="$(CDPATH="" cd "$SCRIPT_DIR/../.." && pwd)"
if [ -z "${KISS_CURRENT_FEATURE:-}" ]; then echo "ERROR: current.feature required" >&2; exit 2; fi
DIR=$(feature_scoped_dir reviews)
OUT="$DIR/quality.md"

SCOPE=$(resolve_auto QR_SCOPE "src/**") || true

if [ "${KISS_DRY_RUN:-0}" = "1" ]; then echo "[dry-run] would write: $OUT (scope=$SCOPE)"; exit 0; fi
if [ -f "$OUT" ]; then echo "Review exists: $OUT" >&2; exit 2; fi
if ! confirm_before_write "Scaffold quality review at $OUT."; then echo "Aborted." >&2; exit 1; fi

sed \
    -e "s|{feature}|$KISS_CURRENT_FEATURE|g" \
    -e "s|{date}|$(date +%Y-%m-%d)|g" \
    -e "s|{scope}|$SCOPE|g" \
    "$SKILL_DIR/templates/quality-review-template.md" > "$OUT"
write_extract "$OUT" "FEATURE=$KISS_CURRENT_FEATURE" "SCOPE=$SCOPE" > /dev/null
echo "Wrote $OUT — agent to populate findings by reading the scoped source files."
