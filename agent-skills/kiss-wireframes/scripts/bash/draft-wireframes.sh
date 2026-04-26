#!/usr/bin/env bash
set -e
SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"
kiss_parse_standard_args "$@"
set -- "${KISS_REST_ARGS[@]}"
if [ "${1:-}" = "--help" ]; then echo "Usage: draft-wireframes.sh [--auto]. Key: UX_PERSONA."; exit 0; fi
read_context
SKILL_DIR="$(CDPATH="" cd "$SCRIPT_DIR/../.." && pwd)"
if [ -z "${KISS_CURRENT_FEATURE:-}" ]; then echo "ERROR: current.feature required" >&2; exit 2; fi
DIR=$(feature_scoped_dir ux)
WF="$DIR/wireframes.md"
UF="$DIR/user-flows.md"
DEBTS="$KISS_REPO_ROOT/$KISS_DOCS_DIR/ux/ux-debts.md"
PERSONA=$(resolve_auto UX_PERSONA "end user") || true

if [ "${KISS_DRY_RUN:-0}" = "1" ]; then echo "[dry-run] would write: $WF + $UF"; exit 0; fi
if ! confirm_before_write "Scaffold wireframes + flows under $DIR."; then echo "Aborted." >&2; exit 1; fi

if [ ! -f "$WF" ]; then
    sed -e "s|{feature}|$KISS_CURRENT_FEATURE|g" -e "s|{date}|$(date +%Y-%m-%d)|g" -e "s|{persona}|$PERSONA|g" \
        "$SKILL_DIR/templates/wireframes-template.md" > "$WF"
    echo "Wrote $WF"
fi
if [ ! -f "$UF" ]; then
    sed -e "s|{feature}|$KISS_CURRENT_FEATURE|g" -e "s|{date}|$(date +%Y-%m-%d)|g" -e "s|{persona}|$PERSONA|g" \
        "$SKILL_DIR/templates/user-flows-template.md" > "$UF"
    echo "Wrote $UF"
fi

write_extract "$WF" "FEATURE=$KISS_CURRENT_FEATURE" "PERSONA=$PERSONA" > /dev/null
append_debt "$DEBTS" UXDEBT "Wireframes + flows scaffolded for $KISS_CURRENT_FEATURE — agent to populate per user stories" > /dev/null
