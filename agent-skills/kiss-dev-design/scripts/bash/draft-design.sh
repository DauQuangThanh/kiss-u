#!/usr/bin/env bash
set -e
SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"
kiss_parse_standard_args "$@"
set -- "${KISS_REST_ARGS[@]}"

if [ "${1:-}" = "--help" ]; then
    cat <<'USAGE'
Usage: draft-design.sh [--auto] [--answers FILE] [--dry-run]
Scaffolds docs/design/<feature>/design.md (+ api-contract.md + data-model.md).
Answer keys: DD_PATTERN, DD_API_STYLE, DD_DATA_STYLE,
  DD_INCLUDE_API_CONTRACT (true/false), DD_INCLUDE_DATA_MODEL (true/false).
USAGE
    exit 0
fi

read_context
SKILL_DIR="$(CDPATH="" cd "$SCRIPT_DIR/../.." && pwd)"

FEATURE="${KISS_CURRENT_FEATURE:-}"
if [ -z "$FEATURE" ]; then
    echo "ERROR: current.feature required — run kiss.specify first." >&2
    exit 2
fi

DIR=$(feature_scoped_dir design)
DEBTS="$KISS_REPO_ROOT/$KISS_DOCS_DIR/architecture/tech-debts.md"

PATTERN=$(resolve_auto DD_PATTERN "hexagonal") || true
API=$(resolve_auto DD_API_STYLE "rest") || true
DATA=$(resolve_auto DD_DATA_STYLE "relational") || true
INC_API=$(resolve_auto DD_INCLUDE_API_CONTRACT "true") || true
INC_DATA=$(resolve_auto DD_INCLUDE_DATA_MODEL "true") || true

OUT="$DIR/design.md"

if [ "${KISS_DRY_RUN:-0}" = "1" ]; then
    echo "[dry-run] would write: $OUT"
    echo "  pattern=$PATTERN api=$API data=$DATA  api-contract=$INC_API data-model=$INC_DATA"
    exit 0
fi
if ! confirm_before_write "Scaffold detailed design under $DIR."; then echo "Aborted." >&2; exit 1; fi

if [ -f "$OUT" ]; then echo "Design exists: $OUT (edit in place)." >&2; exit 2; fi

sed \
    -e "s|{feature}|$FEATURE|g" \
    -e "s|{date}|$(date +%Y-%m-%d)|g" \
    -e "s|{pattern}|$PATTERN|g" \
    -e "s|{api_style}|$API|g" \
    -e "s|{data_style}|$DATA|g" \
    "$SKILL_DIR/templates/design-template.md" > "$OUT"
echo "Wrote $OUT"

if [ "$INC_API" = "true" ]; then
    API_OUT="$DIR/api-contract.md"
    if [ ! -f "$API_OUT" ]; then
        sed -e "s|{feature}|$FEATURE|g" -e "s|{api_style}|$API|g" "$SKILL_DIR/templates/api-contract-template.md" > "$API_OUT"
        echo "Wrote $API_OUT"
    fi
fi

if [ "$INC_DATA" = "true" ]; then
    DATA_OUT="$DIR/data-model.md"
    if [ ! -f "$DATA_OUT" ]; then
        sed -e "s|{feature}|$FEATURE|g" -e "s|{data_style}|$DATA|g" "$SKILL_DIR/templates/data-model-template.md" > "$DATA_OUT"
        echo "Wrote $DATA_OUT"
    fi
fi

write_extract "$OUT" "FEATURE=$FEATURE" "PATTERN=$PATTERN" "API_STYLE=$API" "DATA_STYLE=$DATA" > /dev/null
append_debt "$DEBTS" TDEBT "Design scaffolded for $FEATURE — fill module structure from architecture C4 container" > /dev/null
