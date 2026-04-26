#!/usr/bin/env bash
set -e
SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"
kiss_parse_standard_args "$@"
set -- "${KISS_REST_ARGS[@]}"
if [ "${1:-}" = "--help" ]; then
    echo "Usage: generate-cases.sh [--auto]. Keys: TC_CASES_PER_AC, TC_INCLUDE_BOUNDARY."; exit 0
fi
read_context
SKILL_DIR="$(CDPATH="" cd "$SCRIPT_DIR/../.." && pwd)"
if [ -z "${KISS_CURRENT_FEATURE:-}" ]; then echo "ERROR: current.feature required" >&2; exit 2; fi
DIR=$(feature_scoped_dir testing)
OUT="$DIR/test-cases.md"

if [ -f "$OUT" ]; then echo "Test cases exist: $OUT" >&2; exit 2; fi
if [ "${KISS_DRY_RUN:-0}" = "1" ]; then echo "[dry-run] would write: $OUT"; exit 0; fi
if ! confirm_before_write "Scaffold test cases at $OUT."; then echo "Aborted." >&2; exit 1; fi

sed \
    -e "s|{feature}|$KISS_CURRENT_FEATURE|g" \
    -e "s|{date}|$(date +%Y-%m-%d)|g" \
    "$SKILL_DIR/templates/test-cases-template.md" > "$OUT"
write_extract "$OUT" "FEATURE=$KISS_CURRENT_FEATURE" > /dev/null
echo "Wrote $OUT"
