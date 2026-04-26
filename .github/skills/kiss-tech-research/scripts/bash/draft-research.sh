#!/usr/bin/env bash
set -e
SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"
kiss_parse_standard_args "$@"
set -- "${KISS_REST_ARGS[@]}"

if [ "${1:-}" = "--help" ]; then
    cat <<'USAGE'
Usage: draft-research.sh [--auto] [--answers FILE] [--dry-run]
Scaffolds docs/research/<topic>.md. The agent fills the candidate
blocks using WebSearch/WebFetch.
Answer keys: TR_TOPIC (required), TR_CANDIDATES (comma-separated, required).
USAGE
    exit 0
fi

read_context
SKILL_DIR="$(CDPATH="" cd "$SCRIPT_DIR/../.." && pwd)"
DIR="$KISS_REPO_ROOT/$KISS_DOCS_DIR/research"
DEBTS="$KISS_REPO_ROOT/$KISS_DOCS_DIR/architecture/tech-debts.md"

TOPIC=$(resolve_auto TR_TOPIC "") || missing_topic=1
CANDS=$(resolve_auto TR_CANDIDATES "") || missing_cands=1

if [ -n "${missing_topic:-}" ] || [ -z "$TOPIC" ]; then
    echo "ERROR: TR_TOPIC is required." >&2; exit 2
fi
if [ -n "${missing_cands:-}" ] || [ -z "$CANDS" ]; then
    echo "ERROR: TR_CANDIDATES is required (comma-separated list)." >&2; exit 2
fi

OUT="$DIR/$TOPIC.md"

# Build candidate-table rows.
ROWS_FILE=$(mktemp -t kiss-tr.XXXXXX)
{
    printf '| Candidate | Pros | Cons | Cost signal |\n'
    printf '|---|---|---|---|\n'
    IFS=',' read -ra LIST <<< "$CANDS"
    for c in "${LIST[@]}"; do
        trimmed="$(echo "$c" | awk '{$1=$1;print}')"
        printf '| %s | <pros> | <cons> | <cost> |\n' "$trimmed"
    done
} > "$ROWS_FILE"

if [ "${KISS_DRY_RUN:-0}" = "1" ]; then
    echo "[dry-run] would write: $OUT"
    rm -f "$ROWS_FILE"
    exit 0
fi
if ! confirm_before_write "Scaffold research at $OUT."; then
    rm -f "$ROWS_FILE"
    echo "Aborted." >&2; exit 1
fi

mkdir -p "$DIR"
if [ -f "$OUT" ]; then
    rm -f "$ROWS_FILE"
    echo "Research file exists: $OUT" >&2; exit 2
fi

TPL="$SKILL_DIR/templates/research-template.md"

awk -v topic="$TOPIC" \
    -v datev="$(date +%Y-%m-%d)" \
    -v rowsfile="$ROWS_FILE" '
    function slurp(f,   line, out) {
        while ((getline line < f) > 0) { out = out line "\n" }
        close(f)
        return out
    }
    {
        gsub(/\{topic\}/, topic)
        gsub(/\{date\}/, datev)
        if (index($0, "{candidate_rows}")) {
            sub(/\{candidate_rows\}/, slurp(rowsfile))
        }
        print
    }
' "$TPL" > "$OUT"

rm -f "$ROWS_FILE"

write_extract "$OUT" "TOPIC=$TOPIC" "CANDIDATES=$CANDS" > /dev/null
echo "Wrote $OUT"
append_debt "$DEBTS" TDEBT "Research scaffolded for '$TOPIC' — candidates: $CANDS (agent to fill via WebSearch/WebFetch)" > /dev/null
