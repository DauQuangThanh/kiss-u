#!/usr/bin/env bash
# kiss-retrospective: scaffold docs/agile/retro-sprint-NN.md from notes.
set -e
SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

NOTES_FILE=""
filtered=()
while [ $# -gt 0 ]; do
    case "$1" in
        --notes)
            if [ $# -lt 2 ]; then echo "--notes requires a file" >&2; exit 1; fi
            NOTES_FILE="$2"; shift 2;;
        *) filtered+=("$1"); shift;;
    esac
done
kiss_parse_standard_args "${filtered[@]}"
set -- "${KISS_REST_ARGS[@]}"

if [ "${1:-}" = "--help" ]; then
    cat <<'USAGE'
Usage: synthesize-retro.sh [--auto] [--dry-run] [--help] [--notes FILE]

Scaffolds docs/agile/retro-sprint-NN.md from the team's retro notes.
Notes source: --notes FILE, stdin, or $RETRO_NOTES.
Answer keys: RETRO_SPRINT, RETRO_FORMAT.
USAGE
    exit 0
fi

read_context
SKILL_DIR="$(CDPATH="" cd "$SCRIPT_DIR/../.." && pwd)"
DIR="$KISS_REPO_ROOT/$KISS_DOCS_DIR/agile"
DEBTS="$DIR/agile-debts.md"

SPRINT=$(resolve_auto RETRO_SPRINT "") || true
FORMAT=$(resolve_auto RETRO_FORMAT "wwwdt") || true

# Auto-detect sprint
if [ -z "$SPRINT" ] && [ -d "$DIR" ]; then
    SPRINT=$(ls "$DIR" 2>/dev/null | grep -Eo '^sprint-[0-9]+-plan\.md$' | grep -Eo '[0-9]+' | sort -n | tail -n1 || true)
fi
if [ -z "$SPRINT" ]; then
    echo "ERROR: cannot infer sprint — set RETRO_SPRINT=N" >&2
    exit 2
fi

NOTES=""
if [ -n "$NOTES_FILE" ] && [ -f "$NOTES_FILE" ]; then
    NOTES=$(cat "$NOTES_FILE")
elif [ -n "${RETRO_NOTES:-}" ]; then
    NOTES="$RETRO_NOTES"
elif [ ! -t 0 ]; then
    NOTES=$(cat)
fi

OUT=$(printf '%s/retro-sprint-%02d.md' "$DIR" "$((10#$SPRINT))")

if [ "${KISS_DRY_RUN:-0}" = "1" ]; then
    echo "[dry-run] would write: $OUT"
    echo "[dry-run] sprint=$SPRINT format=$FORMAT  notes bytes=${#NOTES}"
    exit 0
fi

if [ -z "$NOTES" ]; then
    append_debt "$DEBTS" SMDEBT "Retro for sprint $SPRINT requested with no notes — nothing logged" > /dev/null
    echo "ERROR: no retro notes provided (via --notes FILE, stdin, or RETRO_NOTES)." >&2
    exit 3
fi

if ! confirm_before_write "Scaffold retro at $OUT."; then echo "Aborted." >&2; exit 1; fi

mkdir -p "$DIR"
if [ -f "$OUT" ]; then
    echo "Retro already exists: $OUT" >&2
    exit 2
fi

sed \
    -e "s|{sprint}|$SPRINT|g" \
    -e "s|{date}|$(date +%Y-%m-%d)|g" \
    -e "s|{format}|$FORMAT|g" \
    "$SKILL_DIR/templates/retro-template.md" > "$OUT"

{
    printf '\n<!-- raw-notes-begin -->\n```text\n'
    printf '%s\n' "$NOTES"
    printf '```\n<!-- raw-notes-end -->\n'
} >> "$OUT"

write_extract "$OUT" "SPRINT=$SPRINT" "FORMAT=$FORMAT" > /dev/null
echo "Wrote $OUT"
