#!/usr/bin/env bash
set -e
SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"
kiss_parse_standard_args "$@"
set -- "${KISS_REST_ARGS[@]}"
if [ "${1:-}" = "--help" ]; then
    echo "Usage: add-bug.sh [--auto]. Keys: BUG_TITLE, BUG_STEPS, BUG_EXPECTED, BUG_ACTUAL, BUG_SEVERITY, BUG_PRIORITY, BUG_AFFECTED_VERSION, BUG_FAILED_TC, BUG_USER_STORY."
    exit 0
fi
read_context
SKILL_DIR="$(CDPATH="" cd "$SCRIPT_DIR/../.." && pwd)"
DIR="$KISS_REPO_ROOT/$KISS_DOCS_DIR/bugs"

TITLE=$(resolve_auto BUG_TITLE "") || missing_title=1
STEPS=$(resolve_auto BUG_STEPS "") || missing_steps=1
EXPECTED=$(resolve_auto BUG_EXPECTED "") || missing_exp=1
ACTUAL=$(resolve_auto BUG_ACTUAL "") || missing_act=1
SEV=$(resolve_auto BUG_SEVERITY "medium") || true
PRIO=$(resolve_auto BUG_PRIORITY "medium") || true
VER=$(resolve_auto BUG_AFFECTED_VERSION "") || true
TC=$(resolve_auto BUG_FAILED_TC "") || true
US=$(resolve_auto BUG_USER_STORY "") || true

for var in TITLE STEPS EXPECTED ACTUAL; do
    if [ -z "${!var}" ]; then
        echo "ERROR: BUG_$var required" >&2; exit 2
    fi
done

# Next bug number
NEXT=1
if [ -d "$DIR" ]; then
    last=$(ls "$DIR" 2>/dev/null | grep -Eo '^BUG-[0-9]+' | grep -Eo '[0-9]+' | sort -n | tail -n1 || true)
    [ -n "$last" ] && NEXT=$((10#$last + 1))
fi
NUM=$(printf '%03d' "$NEXT")
SLUG=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g; s/-\+/-/g; s/^-//; s/-$//' | cut -c1-60)
OUT="$DIR/BUG-$NUM-$SLUG.md"

if [ "${KISS_DRY_RUN:-0}" = "1" ]; then echo "[dry-run] would write: $OUT"; exit 0; fi
if ! confirm_before_write "Write bug report $NUM at $OUT."; then echo "Aborted." >&2; exit 1; fi
mkdir -p "$DIR"

# Render via awk — multi-line fields (steps/expected/actual) via temp files.
STEPS_MD=$(printf '%b' "$STEPS")  # honour \n escapes in the user's input

TPL="$SKILL_DIR/templates/bug-template.md"
STEPS_FILE=$(mktemp -t kiss-bug.XXXXXX)
EXP_FILE=$(mktemp -t kiss-bug.XXXXXX)
ACT_FILE=$(mktemp -t kiss-bug.XXXXXX)
printf '%s\n' "$STEPS_MD"     > "$STEPS_FILE"
printf '%s\n' "$EXPECTED"     > "$EXP_FILE"
printf '%s\n' "$ACTUAL"       > "$ACT_FILE"

awk -v number="$NUM" \
    -v title="$TITLE" \
    -v datev="$(date +%Y-%m-%d)" \
    -v sev="$SEV" \
    -v prio="$PRIO" \
    -v ftc="${TC:-<none>}" \
    -v us="${US:-<none>}" \
    -v ver="${VER:-<unknown>}" \
    -v stepsfile="$STEPS_FILE" \
    -v expfile="$EXP_FILE" \
    -v actfile="$ACT_FILE" '
    function slurp(f,   line, out) {
        while ((getline line < f) > 0) { out = out line "\n" }
        close(f)
        return out
    }
    {
        gsub(/\{number\}/, number)
        gsub(/\{title\}/, title)
        gsub(/\{date\}/, datev)
        gsub(/\{severity\}/, sev)
        gsub(/\{priority\}/, prio)
        gsub(/\{failed_tc\}/, ftc)
        gsub(/\{user_story\}/, us)
        gsub(/\{affected_version\}/, ver)
        if (index($0, "{steps}")) {
            sub(/\{steps\}/, slurp(stepsfile))
        }
        if (index($0, "{expected}")) {
            sub(/\{expected\}/, slurp(expfile))
        }
        if (index($0, "{actual}")) {
            sub(/\{actual\}/, slurp(actfile))
        }
        print
    }
' "$TPL" > "$OUT"

rm -f "$STEPS_FILE" "$EXP_FILE" "$ACT_FILE"

write_extract "$OUT" "BUG_ID=BUG-$NUM" "SEVERITY=$SEV" "PRIORITY=$PRIO" "FAILED_TC=$TC" "USER_STORY=$US" > /dev/null
echo "Wrote $OUT"
