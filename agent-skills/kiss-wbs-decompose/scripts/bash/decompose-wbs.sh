#!/usr/bin/env bash
set -e
SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"
kiss_parse_standard_args "$@"
set -- "${KISS_REST_ARGS[@]}"

if [ "${1:-}" = "--help" ]; then
    cat <<'USAGE'
Usage: decompose-wbs.sh [--auto] [--answers FILE] [--dry-run] [--help]

Decomposes the project WBS into feature stub directories under specs/.
Requires docs/project/project-plan.md to exist.

Answer keys: WBS_DECOMPOSE_LEVEL, WBS_INCLUDE_SUMMARIES, WBS_PREFIX_RESET.
USAGE
    exit 0
fi

read_context

SKILL_DIR="$(CDPATH="" cd "$SCRIPT_DIR/../.." && pwd)"
PLAN="$KISS_REPO_ROOT/$KISS_DOCS_DIR/project/project-plan.md"
INDEX_DIR=$(worktype_dir "project")
INDEX_OUT="$INDEX_DIR/wbs-index.md"
DEBTS="$INDEX_DIR/wbs-debts.md"

if [ ! -f "$PLAN" ]; then
    echo "ERROR: project-plan.md not found at $PLAN. Run /kiss.project-planning first." >&2
    exit 2
fi

WBS_LEVEL=$(resolve_auto WBS_DECOMPOSE_LEVEL "3") || true

if [ "${KISS_DRY_RUN:-0}" = "1" ]; then
    echo "[dry-run] would parse WBS from: $PLAN"
    echo "  decompose_level=$WBS_LEVEL"
    echo "  output_index=$INDEX_OUT"
    exit 0
fi

if ! confirm_before_write "Decompose WBS from $PLAN into feature stubs."; then
    echo "Aborted." >&2
    exit 1
fi

DATE=$(date +%Y-%m-%d)
SPECS_ROOT="$KISS_REPO_ROOT/$KISS_SPECS_DIR"
mkdir -p "$SPECS_ROOT"

# Find the next available NNN prefix
NEXT_NUM=1
if [ -d "$SPECS_ROOT" ]; then
    last=$(ls "$SPECS_ROOT" 2>/dev/null | grep -Eo '^[0-9]+' | sort -n | tail -n1 || true)
    [ -n "$last" ] && NEXT_NUM=$((10#$last + 1))
fi

# Write index header
cat > "$INDEX_OUT" <<EOF
# WBS Feature Index

**Project:** $(basename "$KISS_REPO_ROOT")
**Generated:** $DATE
**Source:** $PLAN

| WBS ID | Title | Feature Directory | Status |
|---|---|---|---|
EOF

echo "INFO: WBS decomposition requires AI to parse the WBS from $PLAN"
echo "      The AI will extract leaf nodes, generate slugs, and create stubs."
echo "      Wrote index scaffold to $INDEX_OUT"
echo "      Next: AI populates index rows and creates spec stubs per WBS leaf"

write_extract "$INDEX_OUT" \
    "WBS_LEAF_COUNT=0" \
    "FEATURE_DIRS_CREATED=0" \
    "NEXT_NUM=$NEXT_NUM" \
    "WBS_DECOMPOSE_LEVEL=$WBS_LEVEL" \
    "GENERATED_DATE=$DATE" > /dev/null
