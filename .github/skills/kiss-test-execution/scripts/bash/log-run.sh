#!/usr/bin/env bash
set -e
SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"
kiss_parse_standard_args "$@"
set -- "${KISS_REST_ARGS[@]}"
if [ "${1:-}" = "--help" ]; then
    echo "Usage: log-run.sh [--auto]. Keys: TE_RUN_DATE, TE_PASSED, TE_FAILED, TE_SKIPPED, TE_FAILED_TC_IDS, TE_NOTES."; exit 0
fi
read_context
SKILL_DIR="$(CDPATH="" cd "$SCRIPT_DIR/../.." && pwd)"
if [ -z "${KISS_CURRENT_FEATURE:-}" ]; then echo "ERROR: current.feature required" >&2; exit 2; fi
DIR=$(feature_scoped_dir testing)
OUT="$DIR/execution.md"
DEBTS="$DIR/test-debts.md"

DATE_V=$(resolve_auto TE_RUN_DATE "$(date +%Y-%m-%d)") || true
PASSED=$(resolve_auto TE_PASSED "") || missing_passed=1
FAILED=$(resolve_auto TE_FAILED "0") || true
SKIPPED=$(resolve_auto TE_SKIPPED "0") || true
FAILED_IDS=$(resolve_auto TE_FAILED_TC_IDS "") || true
NOTES=$(resolve_auto TE_NOTES "") || true

if [ -n "${missing_passed:-}" ] || [ -z "$PASSED" ]; then
    echo "ERROR: TE_PASSED required" >&2; exit 2
fi

if [ "${KISS_DRY_RUN:-0}" = "1" ]; then echo "[dry-run] would append run $DATE_V to $OUT"; exit 0; fi
if ! confirm_before_write "Append execution run to $OUT."; then echo "Aborted." >&2; exit 1; fi

if [ ! -f "$OUT" ]; then
    sed -e "s|{feature}|$KISS_CURRENT_FEATURE|g" -e "s|{date}|$(date +%Y-%m-%d)|g" \
        -e "s|{run_date}||g" -e "s|{passed}||g" -e "s|{failed}||g" -e "s|{skipped}||g" \
        -e "s|{notes}||g" -e "s|{failed_ids}||g" \
        "$SKILL_DIR/templates/execution-template.md" > "$OUT"
    # strip placeholder "### Run" block
    awk 'BEGIN{skip=0} /^### Run /{skip=1} skip && /^---$/{skip=0; next} !skip' "$OUT" > "$OUT.tmp"
    mv "$OUT.tmp" "$OUT"
fi

{
    printf '\n### Run %s\n\n' "$DATE_V"
    printf -- '- **Passed:** %s\n' "$PASSED"
    printf -- '- **Failed:** %s\n' "$FAILED"
    printf -- '- **Skipped:** %s\n' "$SKIPPED"
    printf -- '- **Notes:** %s\n' "${NOTES:-<none>}"
    printf -- '- **Failed TC ids:** %s\n\n' "${FAILED_IDS:-<none>}"
    if [ -n "$FAILED_IDS" ]; then
        printf '#### Links to bug reports\n\n'
        printf '| Failed TC | Bug id | Status |\n|---|---|---|\n'
        IFS=',' read -ra IDS <<< "$FAILED_IDS"
        for id in "${IDS[@]}"; do
            trimmed="$(echo "$id" | awk '{$1=$1;print}')"
            printf '| %s | BUG-TBD | Open |\n' "$trimmed"
        done
        printf '\n'
    fi
    printf -- '---\n'
} >> "$OUT"

TOTAL=$((10#$PASSED + 10#$FAILED + 10#$SKIPPED))
write_extract "$OUT" "LAST_RUN=$DATE_V" "TOTAL=$TOTAL" "PASSED=$PASSED" "FAILED=$FAILED" "SKIPPED=$SKIPPED" > /dev/null
echo "Appended run $DATE_V to $OUT"

if [ "$FAILED" != "0" ]; then
    append_debt "$DEBTS" TQDEBT "Run $DATE_V had $FAILED failed TC(s): ${FAILED_IDS:-<unnamed>} — raise bug reports" > /dev/null
fi
