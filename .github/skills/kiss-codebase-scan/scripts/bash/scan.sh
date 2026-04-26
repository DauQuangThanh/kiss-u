#!/usr/bin/env bash
set -e
SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"
kiss_parse_standard_args "$@"
set -- "${KISS_REST_ARGS[@]}"
if [ "${1:-}" = "--help" ]; then echo "Usage: scan.sh [--auto]. Keys: CS_EXCLUDE_GLOBS."; exit 0; fi
read_context
SKILL_DIR="$(CDPATH="" cd "$SCRIPT_DIR/../.." && pwd)"
DIR="$KISS_REPO_ROOT/$KISS_DOCS_DIR/analysis"
OUT="$DIR/codebase-scan.md"
EXCL=$(resolve_auto CS_EXCLUDE_GLOBS "node_modules/**,dist/**,.venv/**,build/**,target/**") || true

if [ "${KISS_DRY_RUN:-0}" = "1" ]; then echo "[dry-run] would write: $OUT"; exit 0; fi
if [ -f "$OUT" ]; then echo "Scan doc exists: $OUT" >&2; exit 2; fi
if ! confirm_before_write "Scaffold codebase scan at $OUT."; then echo "Aborted." >&2; exit 1; fi
mkdir -p "$DIR"
sed -e "s|{date}|$(date +%Y-%m-%d)|g" -e "s|{root}|$KISS_REPO_ROOT|g" -e "s|{excludes}|$EXCL|g" \
    "$SKILL_DIR/templates/scan-template.md" > "$OUT"
write_extract "$OUT" "ROOT=$KISS_REPO_ROOT" "EXCLUDES=$EXCL" > /dev/null
echo "Wrote $OUT — agent to walk the tree and fill tables."
