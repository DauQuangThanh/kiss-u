#!/usr/bin/env bash
set -e
SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"
kiss_parse_standard_args "$@"
set -- "${KISS_REST_ARGS[@]}"

if [ "${1:-}" = "--help" ]; then
    cat <<'USAGE'
Usage: draft-c4.sh [--auto] [--answers FILE] [--dry-run]
Scaffolds docs/architecture/c4-{context,container,component}.md.
Answer keys: C4_LEVEL (context|container|component|all), C4_SYSTEM_NAME.
USAGE
    exit 0
fi

read_context
SKILL_DIR="$(CDPATH="" cd "$SCRIPT_DIR/../.." && pwd)"
DIR="$KISS_REPO_ROOT/$KISS_DOCS_DIR/architecture"
DEBTS="$DIR/tech-debts.md"

LEVEL=$(resolve_auto C4_LEVEL "all") || true
SYS=$(resolve_auto C4_SYSTEM_NAME "${KISS_CURRENT_FEATURE:-system}") || true

case "$LEVEL" in context|container|component|all) ;; *) LEVEL="all" ;; esac

if [ "${KISS_DRY_RUN:-0}" = "1" ]; then
    echo "[dry-run] level=$LEVEL system=$SYS  target: $DIR"
    exit 0
fi

if ! confirm_before_write "Scaffold C4 diagrams under $DIR."; then echo "Aborted." >&2; exit 1; fi

mkdir -p "$DIR"
wrote_any=0
declare -A levels=(
    [context]="c4-context-template.md:c4-context.md"
    [container]="c4-container-template.md:c4-container.md"
    [component]="c4-component-template.md:c4-component.md"
)

for key in context container component; do
    if [ "$LEVEL" != "all" ] && [ "$LEVEL" != "$key" ]; then continue; fi
    tpl_target="${levels[$key]}"
    tpl="$SKILL_DIR/templates/${tpl_target%:*}"
    out="$DIR/${tpl_target#*:}"
    if [ -f "$out" ]; then
        echo "Skip $out (already exists)"
        continue
    fi
    sed -e "s|{date}|$(date +%Y-%m-%d)|g" -e "s|{system_name}|$SYS|g" "$tpl" > "$out"
    echo "Wrote $out"
    wrote_any=1
done

if [ "$wrote_any" = "1" ]; then
    append_debt "$DEBTS" TDEBT "C4 diagrams scaffolded for '$SYS' — agent to tailor nodes + edges using intake.md and ADRs" > /dev/null
fi
