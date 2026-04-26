#!/usr/bin/env bash
set -e
SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"
kiss_parse_standard_args "$@"
set -- "${KISS_REST_ARGS[@]}"
if [ "${1:-}" = "--help" ]; then
    echo "Usage: scaffold-regression.sh [--auto]. Keys: RT_BUG_ID (required), RT_LEVEL."; exit 0
fi
read_context
SKILL_DIR="$(CDPATH="" cd "$SCRIPT_DIR/../.." && pwd)"
DIR="$KISS_REPO_ROOT/$KISS_DOCS_DIR/testing"
OUT="$DIR/regression-index.md"
DEBTS="$DIR/test-debts.md"

BUG=$(resolve_auto RT_BUG_ID "") || missing_bug=1
LEVEL=$(resolve_auto RT_LEVEL "integration") || true
if [ -z "$BUG" ]; then echo "ERROR: RT_BUG_ID required" >&2; exit 2; fi

if [ "${KISS_DRY_RUN:-0}" = "1" ]; then echo "[dry-run] would update: $OUT  (bug=$BUG level=$LEVEL)"; exit 0; fi
if ! confirm_before_write "Update regression index at $OUT."; then echo "Aborted." >&2; exit 1; fi

mkdir -p "$DIR"
if [ ! -f "$OUT" ]; then
    sed -e "s|{date}|$(date +%Y-%m-%d)|g" "$SKILL_DIR/templates/regression-index-template.md" > "$OUT"
    # strip placeholder row
    awk '!/^\| BUG-NN \|/' "$OUT" > "$OUT.tmp" && mv "$OUT.tmp" "$OUT"
fi

# Append row if absent
if ! grep -q "^| $BUG |" "$OUT"; then
    printf '| %s | Open | %s | <tests/regression/...> | agent to fill path + notes |\n' "$BUG" "$LEVEL" >> "$OUT"
    echo "Added $BUG row to $OUT"
else
    echo "$BUG already present in $OUT"
fi

append_debt "$DEBTS" TQDEBT "Regression test scaffolded for $BUG — agent must write the actual test file using bug's repro steps" > /dev/null
