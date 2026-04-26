#!/usr/bin/env bash
# kiss-sprint-planning: scaffold docs/agile/sprint-NN-plan.md.
set -e
SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"
kiss_parse_standard_args "$@"
set -- "${KISS_REST_ARGS[@]}"

if [ "${1:-}" = "--help" ]; then
    cat <<'USAGE'
Usage: draft-sprint.sh [--auto] [--answers FILE] [--dry-run] [--help]
Scaffolds docs/agile/sprint-NN-plan.md. Answer keys:
  SP_SPRINT_NUMBER, SP_GOAL, SP_VELOCITY, SP_CAPACITY, SP_START_DATE, SP_END_DATE.
USAGE
    exit 0
fi

read_context
SKILL_DIR="$(CDPATH="" cd "$SCRIPT_DIR/../.." && pwd)"
DIR="$KISS_REPO_ROOT/$KISS_DOCS_DIR/agile"
DEBTS="$DIR/agile-debts.md"

# Auto-increment sprint number if not provided.
NEXT=1
if [ -d "$DIR" ]; then
    last=$(ls "$DIR" 2>/dev/null | grep -Eo '^sprint-[0-9]+-plan\.md$' | grep -Eo '[0-9]+' | sort -n | tail -n1 || true)
    [ -n "$last" ] && NEXT=$((10#$last + 1))
fi

SPRINT=$(resolve_auto SP_SPRINT_NUMBER "$NEXT") || true
GOAL=$(resolve_auto SP_GOAL "") || missing_goal=1
VELOCITY=$(resolve_auto SP_VELOCITY "") || missing_vel=1
CAPACITY=$(resolve_auto SP_CAPACITY "$VELOCITY") || true
START=$(resolve_auto SP_START_DATE "$(date +%Y-%m-%d)") || true
if date -u -d "$START +14 days" +%Y-%m-%d >/dev/null 2>&1; then
    END_DEFAULT=$(date -u -d "$START +14 days" +%Y-%m-%d)
else
    END_DEFAULT=$(date -u -v+14d -j -f %Y-%m-%d "$START" +%Y-%m-%d 2>/dev/null || echo "$START")
fi
END=$(resolve_auto SP_END_DATE "$END_DEFAULT") || true

OUT=$(printf '%s/sprint-%02d-plan.md' "$DIR" "$((10#$SPRINT))")

if [ "${KISS_DRY_RUN:-0}" = "1" ]; then
    echo "[dry-run] would write: $OUT"
    echo "[dry-run] goal: ${GOAL:-<missing>}"
    echo "[dry-run] velocity=${VELOCITY:-<missing>} capacity=$CAPACITY  $START → $END"
    exit 0
fi

if ! confirm_before_write "Scaffold sprint plan at $OUT."; then echo "Aborted." >&2; exit 1; fi

mkdir -p "$DIR"
if [ -f "$OUT" ]; then echo "Sprint plan exists: $OUT" >&2; exit 2; fi

PREV=$((SPRINT - 1))
sed \
    -e "s|{sprint_number}|$SPRINT|g" \
    -e "s|{prev_sprint}|$PREV|g" \
    -e "s|{goal}|${GOAL:-<TBD>}|g" \
    -e "s|{velocity}|${VELOCITY:-<TBD>}|g" \
    -e "s|{capacity}|${CAPACITY:-<TBD>}|g" \
    -e "s|{start_date}|$START|g" \
    -e "s|{end_date}|$END|g" \
    "$SKILL_DIR/templates/sprint-plan-template.md" > "$OUT"

write_extract "$OUT" "SPRINT=$SPRINT" "GOAL=$GOAL" "VELOCITY=$VELOCITY" "CAPACITY=$CAPACITY" "START=$START" "END=$END" > /dev/null
echo "Wrote $OUT"

if [ -n "${missing_goal:-}" ]; then
    append_debt "$DEBTS" SMDEBT "Sprint $SPRINT has no goal — propose one before team commits (Priority: 🔴 Blocking)" > /dev/null
fi
if [ -n "${missing_vel:-}" ]; then
    append_debt "$DEBTS" SMDEBT "Sprint $SPRINT has no velocity figure — team's recent average required" > /dev/null
fi
