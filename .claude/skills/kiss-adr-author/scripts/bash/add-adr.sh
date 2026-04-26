#!/usr/bin/env bash
set -e
SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"
kiss_parse_standard_args "$@"
set -- "${KISS_REST_ARGS[@]}"

if [ "${1:-}" = "--help" ]; then
    cat <<'USAGE'
Usage: add-adr.sh [--auto] [--answers FILE] [--dry-run]
Appends an ADR to docs/decisions/ADR-NNN-<slug>.md (auto-numbered).
Answer keys: ADR_TITLE, ADR_DECIDER, ADR_CONTEXT, ADR_DECISION,
  ADR_CONSEQUENCES, ADR_STATUS, ADR_SUPERSEDES.
USAGE
    exit 0
fi

read_context
SKILL_DIR="$(CDPATH="" cd "$SCRIPT_DIR/../.." && pwd)"
DIR="$KISS_REPO_ROOT/$KISS_DOCS_DIR/decisions"
DEBTS="$KISS_REPO_ROOT/$KISS_DOCS_DIR/architecture/tech-debts.md"

TITLE=$(resolve_auto ADR_TITLE "") || missing_title=1
DECIDER=$(resolve_auto ADR_DECIDER "") || missing_decider=1
CONTEXT=$(resolve_auto ADR_CONTEXT "") || missing_context=1
DECISION=$(resolve_auto ADR_DECISION "") || missing_decision=1
CONSEQ=$(resolve_auto ADR_CONSEQUENCES "") || true
STATUS=$(resolve_auto ADR_STATUS "Proposed") || true
SUP=$(resolve_auto ADR_SUPERSEDES "") || true

case "$STATUS" in Proposed|Accepted|Deprecated|Superseded) ;; *) STATUS="Proposed";; esac

if [ -z "$TITLE" ]; then echo "ERROR: ADR_TITLE is required" >&2; exit 2; fi

# Next ADR number
NEXT=1
if [ -d "$DIR" ]; then
    last=$(ls "$DIR" 2>/dev/null | grep -Eo '^ADR-[0-9]+' | grep -Eo '[0-9]+' | sort -n | tail -n1 || true)
    [ -n "$last" ] && NEXT=$((10#$last + 1))
fi
NUM=$(printf '%03d' "$NEXT")

# slug
SLUG=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g; s/-\+/-/g; s/^-//; s/-$//' | cut -c1-60)
OUT="$DIR/ADR-$NUM-$SLUG.md"
SUP_LINE=""
[ -n "$SUP" ] && SUP_LINE="**Supersedes:** $SUP"

if [ "${KISS_DRY_RUN:-0}" = "1" ]; then
    echo "[dry-run] would write: $OUT"
    echo "  title=$TITLE  status=$STATUS  decider=${DECIDER:-<TBD>}"
    exit 0
fi

if ! confirm_before_write "Write ADR $NUM at $OUT."; then echo "Aborted." >&2; exit 1; fi

mkdir -p "$DIR"
if [ -f "$OUT" ]; then echo "ADR already exists: $OUT" >&2; exit 2; fi

# Use awk with multi-line field substitution via temp files.
TPL="$SKILL_DIR/templates/adr-template.md"
CTX_FILE=$(mktemp -t kiss-adr.XXXXXX)
DEC_FILE=$(mktemp -t kiss-adr.XXXXXX)
CON_FILE=$(mktemp -t kiss-adr.XXXXXX)
printf '%s\n' "${CONTEXT:-<TBD>}"   > "$CTX_FILE"
printf '%s\n' "${DECISION:-<TBD>}"  > "$DEC_FILE"
printf '%s\n' "${CONSEQ:-<TBD>}"    > "$CON_FILE"

awk -v number="$NUM" \
    -v title="$TITLE" \
    -v datev="$(date +%Y-%m-%d)" \
    -v status="$STATUS" \
    -v decider="${DECIDER:-<TBD>}" \
    -v supline="$SUP_LINE" \
    -v ctxfile="$CTX_FILE" \
    -v decfile="$DEC_FILE" \
    -v confile="$CON_FILE" '
    function slurp(f,   line, out) {
        while ((getline line < f) > 0) { out = out line "\n" }
        close(f)
        return out
    }
    {
        gsub(/\{number\}/, number)
        gsub(/\{title\}/, title)
        gsub(/\{date\}/, datev)
        gsub(/\{status\}/, status)
        gsub(/\{decider\}/, decider)
        gsub(/\{supersedes_line\}/, supline)
        if (index($0, "{context}")) {
            sub(/\{context\}/, slurp(ctxfile))
        }
        if (index($0, "{decision}")) {
            sub(/\{decision\}/, slurp(decfile))
        }
        if (index($0, "{consequences}")) {
            sub(/\{consequences\}/, slurp(confile))
        }
        print
    }
' "$TPL" > "$OUT"

rm -f "$CTX_FILE" "$DEC_FILE" "$CON_FILE"

write_extract "$OUT" "ADR_ID=ADR-$NUM" "TITLE=$TITLE" "STATUS=$STATUS" "DECIDER=$DECIDER" > /dev/null
echo "Wrote $OUT"

if [ -n "${missing_context:-}" ] || [ -n "${missing_decision:-}" ]; then
    append_debt "$DEBTS" TDEBT "ADR-$NUM ('$TITLE') has incomplete context or decision — flesh out before marking Accepted" > /dev/null
fi
if [ -n "${missing_decider:-}" ]; then
    append_debt "$DEBTS" TDEBT "ADR-$NUM has no decider recorded" > /dev/null
fi
