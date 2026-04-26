#!/usr/bin/env bash
# kiss-backlog: append a backlog item to docs/product/backlog.md.

set -e
SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"
kiss_parse_standard_args "$@"
set -- "${KISS_REST_ARGS[@]}"

if [ "${1:-}" = "--help" ]; then
    cat <<'USAGE'
Usage: add-item.sh [--auto] [--answers FILE] [--dry-run] [--help]
Appends a backlog item to docs/product/backlog.md.
Answer keys: BL_TITLE, BL_PRIORITY, BL_SIZE, BL_STATUS, BL_STORY_REF.
USAGE
    exit 0
fi

read_context
SKILL_DIR="$(CDPATH="" cd "$SCRIPT_DIR/../.." && pwd)"
DIR="$KISS_REPO_ROOT/$KISS_DOCS_DIR/product"
BACKLOG="$DIR/backlog.md"
DEBTS="$DIR/product-debts.md"

TITLE=$(resolve_auto BL_TITLE "") || missing_title=1
PRIORITY=$(resolve_auto BL_PRIORITY "99") || true
SIZE=$(resolve_auto BL_SIZE "M") || defaulted_size=1
STATUS=$(resolve_auto BL_STATUS "New") || true
STORY_REF=$(resolve_auto BL_STORY_REF "") || missing_ref=1

case "$SIZE" in XS|S|M|L|XL) ;; *) SIZE="M" ;; esac
case "$STATUS" in New|Ready|"In progress"|Done|Cut) ;; *) STATUS="New" ;; esac

if [ "${KISS_DRY_RUN:-0}" = "1" ]; then
    echo "[dry-run] would append item to: $BACKLOG"
    echo "  title=${TITLE:-<missing>}  priority=$PRIORITY  size=$SIZE  status=$STATUS  ref=${STORY_REF:-<none>}"
    exit 0
fi

if ! confirm_before_write "Append backlog item to $BACKLOG."; then
    echo "Aborted." >&2; exit 1
fi

mkdir -p "$DIR"

if [ ! -f "$BACKLOG" ]; then
    sed "s|{date}|$(date +%Y-%m-%d)|g" "$SKILL_DIR/templates/backlog-template.md" > "$BACKLOG"
    # strip placeholder data row
    awk 'BEGIN{keep=1} /^\| BL-01 \|/{keep=0; next} keep' "$BACKLOG" > "$BACKLOG.tmp" && mv "$BACKLOG.tmp" "$BACKLOG"
fi

# Next id
NEXT=1
last=$(grep -Eo '^\| BL-[0-9]+' "$BACKLOG" 2>/dev/null | grep -Eo '[0-9]+$' | sort -n | tail -n1 || true)
[ -n "$last" ] && NEXT=$((10#$last + 1))
BLID=$(printf 'BL-%02d' "$NEXT")

printf '| %s | %s | %s | %s | %s | %s |\n' "$BLID" "$PRIORITY" "${TITLE:-<TBD>}" "$SIZE" "$STATUS" "${STORY_REF:-<none>}" >> "$BACKLOG"

TOTAL=$(grep -cE '^\| BL-[0-9]+' "$BACKLOG" 2>/dev/null) || true; TOTAL=${TOTAL:-0}
write_extract "$BACKLOG" "TOTAL_ITEMS=$TOTAL" "LAST_ADDED=$BLID" > /dev/null
echo "Appended $BLID to $BACKLOG"

if [ -n "${missing_title:-}" ]; then
    append_debt "$DEBTS" PODEBT "Backlog item $BLID has no title" > /dev/null
fi
if [ -n "${missing_ref:-}" ]; then
    append_debt "$DEBTS" PODEBT "Backlog item $BLID has no spec reference (Area: Traceability)" > /dev/null
fi
if [ -n "${defaulted_size:-}" ]; then
    append_debt "$DEBTS" PODEBT "Backlog item $BLID size defaulted to M — confirm with team" > /dev/null
fi
