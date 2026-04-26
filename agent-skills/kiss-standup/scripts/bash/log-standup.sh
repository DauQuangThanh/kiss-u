#!/usr/bin/env bash
# kiss-standup: log today's standup from notes.
set -e
SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

NOTES_FILE=""
# Extract --notes FILE before the common parser sees it.
filtered=()
while [ $# -gt 0 ]; do
    case "$1" in
        --notes)
            if [ $# -lt 2 ]; then echo "--notes requires a file" >&2; exit 1; fi
            NOTES_FILE="$2"; shift 2;;
        *)
            filtered+=("$1"); shift;;
    esac
done
kiss_parse_standard_args "${filtered[@]}"
set -- "${KISS_REST_ARGS[@]}"

if [ "${1:-}" = "--help" ]; then
    cat <<'USAGE'
Usage: log-standup.sh [--auto] [--answers FILE] [--dry-run] [--help] [--notes FILE]

Appends today's standup log to docs/agile/standups/YYYY-MM-DD.md.

Notes source (one of):
  --notes FILE          read notes from a file
  stdin (piped)         read notes from stdin
  STANDUP_NOTES env var inline notes

Answer keys: STANDUP_DATE, STANDUP_SPRINT, STANDUP_NOTES.
USAGE
    exit 0
fi

read_context
SKILL_DIR="$(CDPATH="" cd "$SCRIPT_DIR/../.." && pwd)"
DIR="$KISS_REPO_ROOT/$KISS_DOCS_DIR/agile/standups"
DEBTS="$KISS_REPO_ROOT/$KISS_DOCS_DIR/agile/agile-debts.md"

DATE=$(resolve_auto STANDUP_DATE "$(date +%Y-%m-%d)") || true
SPRINT=$(resolve_auto STANDUP_SPRINT "") || true

# Auto-detect sprint if not provided
if [ -z "$SPRINT" ]; then
    plans_dir="$KISS_REPO_ROOT/$KISS_DOCS_DIR/agile"
    if [ -d "$plans_dir" ]; then
        SPRINT=$(ls "$plans_dir" 2>/dev/null | grep -Eo '^sprint-[0-9]+-plan\.md$' | grep -Eo '[0-9]+' | sort -n | tail -n1 || true)
    fi
    SPRINT="${SPRINT:-unknown}"
fi

# Collect notes
NOTES=""
if [ -n "$NOTES_FILE" ] && [ -f "$NOTES_FILE" ]; then
    NOTES=$(cat "$NOTES_FILE")
elif [ -n "${STANDUP_NOTES:-}" ]; then
    NOTES="$STANDUP_NOTES"
elif [ ! -t 0 ]; then
    NOTES=$(cat)
fi

OUT="$DIR/$DATE.md"

if [ "${KISS_DRY_RUN:-0}" = "1" ]; then
    echo "[dry-run] would write: $OUT"
    echo "[dry-run] sprint: $SPRINT"
    echo "[dry-run] notes bytes: ${#NOTES}"
    exit 0
fi

if [ -z "$NOTES" ]; then
    echo "ERROR: no standup notes provided (via --notes FILE, stdin, or STANDUP_NOTES)." >&2
    append_debt "$DEBTS" SMDEBT "Standup $DATE requested with no notes — nothing logged" > /dev/null
    exit 3
fi

if ! confirm_before_write "Log standup at $OUT."; then echo "Aborted." >&2; exit 1; fi

mkdir -p "$DIR"
if [ -f "$OUT" ]; then
    echo "Standup for $DATE already logged: $OUT" >&2
    echo "Edit in place or pick a different STANDUP_DATE." >&2
    exit 2
fi

# Produce the structured file. The AI agent refines structure; this
# script seeds the template + appends the raw notes verbatim.
sed -e "s|{date}|$DATE|g" -e "s|{sprint}|$SPRINT|g" \
    "$SKILL_DIR/templates/standup-template.md" > "$OUT"

{
    printf '\n<!-- raw-notes-begin -->\n```text\n'
    printf '%s\n' "$NOTES"
    printf '```\n<!-- raw-notes-end -->\n'
} >> "$OUT"

echo "Logged $OUT"
