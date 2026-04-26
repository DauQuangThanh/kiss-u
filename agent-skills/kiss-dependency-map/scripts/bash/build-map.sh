#!/usr/bin/env bash
set -e
SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"
kiss_parse_standard_args "$@"
set -- "${KISS_REST_ARGS[@]}"
if [ "${1:-}" = "--help" ]; then echo "Usage: build-map.sh [--auto]. Key: DM_MAX_MODULES."; exit 0; fi
read_context
SKILL_DIR="$(CDPATH="" cd "$SCRIPT_DIR/../.." && pwd)"
DIR="$KISS_REPO_ROOT/$KISS_DOCS_DIR/analysis"
OUT="$DIR/dependencies.md"
MAX=$(resolve_auto DM_MAX_MODULES "25") || true
if [ "${KISS_DRY_RUN:-0}" = "1" ]; then echo "[dry-run] would write: $OUT"; exit 0; fi
if [ -f "$OUT" ]; then echo "Dep map exists: $OUT" >&2; exit 2; fi
if ! confirm_before_write "Scaffold dependency map at $OUT."; then echo "Aborted." >&2; exit 1; fi
mkdir -p "$DIR"
sed -e "s|{date}|$(date +%Y-%m-%d)|g" -e "s|{max_modules}|$MAX|g" "$SKILL_DIR/templates/dependencies-template.md" > "$OUT"
write_extract "$OUT" "MAX_MODULES=$MAX" > /dev/null
echo "Wrote $OUT"
