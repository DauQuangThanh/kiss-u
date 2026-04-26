#!/usr/bin/env bash
set -e
SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"
kiss_parse_standard_args "$@"
set -- "${KISS_REST_ARGS[@]}"
if [ "${1:-}" = "--help" ]; then
    echo "Usage: triage.sh [--auto]. Key: BT_STALE_DAYS."; exit 0
fi
read_context
SKILL_DIR="$(CDPATH="" cd "$SCRIPT_DIR/../.." && pwd)"
DIR="$KISS_REPO_ROOT/$KISS_DOCS_DIR/bugs"
OUT="$DIR/triage.md"

STALE=$(resolve_auto BT_STALE_DAYS "30") || true

if [ "${KISS_DRY_RUN:-0}" = "1" ]; then echo "[dry-run] would (re-)write: $OUT"; exit 0; fi
if ! confirm_before_write "Rewrite triage list at $OUT."; then echo "Aborted." >&2; exit 1; fi
mkdir -p "$DIR"

sed -e "s|{date}|$(date +%Y-%m-%d)|g" -e "s|{stale_days}|$STALE|g" \
    "$SKILL_DIR/templates/triage-template.md" > "$OUT"

OPEN=$(ls "$DIR" 2>/dev/null | grep -cE '^BUG-[0-9]+.*\.md$') || true
OPEN=${OPEN:-0}
write_extract "$OUT" "DATE=$(date +%Y-%m-%d)" "OPEN_BUGS=$OPEN" "STALE_DAYS=$STALE" > /dev/null
echo "Wrote $OUT — $OPEN open bugs. Agent to populate buckets by reading each BUG-*.md."
