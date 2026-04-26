#!/usr/bin/env bash
set -e
SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"
kiss_parse_standard_args "$@"
set -- "${KISS_REST_ARGS[@]}"
if [ "${1:-}" = "--help" ]; then
    echo "Usage: record-fix.sh [--auto]. Keys: CR_BUG_ID, CR_COMMIT, CR_PR, CR_FILES, CR_REGRESSION_TEST, CR_REVIEWER."; exit 0
fi
read_context
SKILL_DIR="$(CDPATH="" cd "$SCRIPT_DIR/../.." && pwd)"
DIR="$KISS_REPO_ROOT/$KISS_DOCS_DIR/bugs"
REG="$DIR/change-register.md"
DEBTS="$DIR/fix-debts.md"

BUG=$(resolve_auto CR_BUG_ID "") || missing_bug=1
COMMIT=$(resolve_auto CR_COMMIT "") || missing_commit=1
PR=$(resolve_auto CR_PR "") || true
FILES=$(resolve_auto CR_FILES "") || true
REGR=$(resolve_auto CR_REGRESSION_TEST "") || missing_regr=1
REVIEWER=$(resolve_auto CR_REVIEWER "") || missing_reviewer=1

for v in BUG COMMIT REVIEWER; do
    eval "val=\${$v:-}"
    if [ -z "$val" ]; then echo "ERROR: CR_$v required" >&2; exit 2; fi
done

if [ "${KISS_DRY_RUN:-0}" = "1" ]; then echo "[dry-run] would append fix row: bug=$BUG commit=$COMMIT pr=$PR reviewer=$REVIEWER"; exit 0; fi
if ! confirm_before_write "Append fix row to $REG."; then echo "Aborted." >&2; exit 1; fi

mkdir -p "$DIR"
if [ ! -f "$REG" ]; then
    sed -e "s|{date}|$(date +%Y-%m-%d)|g" "$SKILL_DIR/templates/change-register-template.md" > "$REG"
    # strip placeholder row
    awk '!/^\| BUG-NN \|/' "$REG" > "$REG.tmp" && mv "$REG.tmp" "$REG"
fi

FILES_CELL=$(echo "${FILES:-<none>}" | tr ';' ',' | sed 's/, /\n/g' | paste -sd',' -)
printf '| %s | %s | `%s` | %s | %s | %s | %s |\n' "$BUG" "$(date +%Y-%m-%d)" "$COMMIT" "${PR:-<none>}" "${FILES_CELL:-<none>}" "${REGR:-<none>}" "$REVIEWER" >> "$REG"

TOTAL=$(grep -cE '^\| BUG-' "$REG" 2>/dev/null) || true; TOTAL=${TOTAL:-0}
write_extract "$REG" "TOTAL_FIXES=$TOTAL" "LAST_FIX=$BUG" "LAST_COMMIT=$COMMIT" > /dev/null
echo "Appended $BUG to $REG"

if [ -n "${missing_regr:-}" ] || [ -z "$REGR" ]; then
    append_debt "$DEBTS" BFDEBT "Fix for $BUG has no regression test linked (commit $COMMIT) — add via kiss-regression-tests" > /dev/null
fi
