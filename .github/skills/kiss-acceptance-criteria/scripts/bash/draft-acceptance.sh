#!/usr/bin/env bash
# kiss-acceptance: scaffold docs/product/acceptance.md for the active feature.
set -e
SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"
kiss_parse_standard_args "$@"
set -- "${KISS_REST_ARGS[@]}"

if [ "${1:-}" = "--help" ]; then
    cat <<'USAGE'
Usage: draft-acceptance.sh [--auto] [--answers FILE] [--dry-run] [--help]
Scaffolds docs/product/acceptance.md for the active feature, seeded from the
template. The agent then fills in Given/When/Then blocks per user story by
reading the spec.
USAGE
    exit 0
fi

read_context
SKILL_DIR="$(CDPATH="" cd "$SCRIPT_DIR/../.." && pwd)"
DIR="$KISS_REPO_ROOT/$KISS_DOCS_DIR/product"
OUT="$DIR/acceptance.md"
DEBTS="$DIR/product-debts.md"

FEATURE="${KISS_CURRENT_FEATURE:-}"
if [ -z "$FEATURE" ]; then
    echo "ERROR: .kiss/context.yml current.feature is not set — run kiss.specify first." >&2
    exit 2
fi

SPEC_REF="$KISS_SPECS_DIR/$FEATURE/spec.md"

if [ "${KISS_DRY_RUN:-0}" = "1" ]; then
    echo "[dry-run] would write: $OUT"
    echo "[dry-run] feature: $FEATURE"
    echo "[dry-run] spec ref: $SPEC_REF"
    exit 0
fi

if ! confirm_before_write "Scaffold acceptance criteria at $OUT."; then
    echo "Aborted." >&2; exit 1
fi

mkdir -p "$DIR"
if [ -f "$OUT" ]; then
    echo "Acceptance file already exists: $OUT (edit in place)." >&2
    exit 2
fi

sed \
    -e "s|{feature}|$FEATURE|g" \
    -e "s|{date}|$(date +%Y-%m-%d)|g" \
    -e "s|{spec_ref}|$SPEC_REF|g" \
    "$SKILL_DIR/templates/acceptance-template.md" > "$OUT"

write_extract "$OUT" "FEATURE=$FEATURE" "SPEC_REF=$SPEC_REF" > /dev/null
echo "Wrote $OUT"

append_debt "$DEBTS" PODEBT "Acceptance scaffolded for $FEATURE — populate Given/When/Then blocks per user story" > /dev/null
