#!/usr/bin/env bash
set -e
SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"
kiss_parse_standard_args "$@"
set -- "${KISS_REST_ARGS[@]}"

if [ "${1:-}" = "--help" ]; then
    cat <<'USAGE'
Usage: draft-intake.sh [--auto] [--answers FILE] [--dry-run]
Scaffolds docs/architecture/intake.md.
USAGE
    exit 0
fi

read_context
SKILL_DIR="$(CDPATH="" cd "$SCRIPT_DIR/../.." && pwd)"
DIR="$KISS_REPO_ROOT/$KISS_DOCS_DIR/architecture"
OUT="$DIR/intake.md"
DEBTS="$DIR/tech-debts.md"

TEAM_BAND=$(resolve_auto AI_TEAM_SIZE_BAND "6-15") || true
QPS=$(resolve_auto AI_PEAK_QPS "") || missing_qps=1
SLA=$(resolve_auto AI_SLA_TARGET "99.9%") || true
DEPLOY=$(resolve_auto AI_DEPLOY_PREF "no-preference") || true

if [ "${KISS_DRY_RUN:-0}" = "1" ]; then
    echo "[dry-run] would write: $OUT"
    exit 0
fi

if ! confirm_before_write "Scaffold architecture intake at $OUT."; then echo "Aborted." >&2; exit 1; fi
mkdir -p "$DIR"
if [ -f "$OUT" ]; then echo "Intake exists: $OUT" >&2; exit 2; fi

sed \
    -e "s|{date}|$(date +%Y-%m-%d)|g" \
    -e "s|{feature}|${KISS_CURRENT_FEATURE:-<none>}|g" \
    -e "s|{team_size_band}|$TEAM_BAND|g" \
    -e "s|{peak_qps}|${QPS:-<TBD>}|g" \
    -e "s|{sla_target}|$SLA|g" \
    -e "s|{deploy_pref}|$DEPLOY|g" \
    "$SKILL_DIR/templates/intake-template.md" > "$OUT"

write_extract "$OUT" "TEAM_SIZE_BAND=$TEAM_BAND" "SLA_TARGET=$SLA" "DEPLOY_PREF=$DEPLOY" "PEAK_QPS=$QPS" > /dev/null
echo "Wrote $OUT"

if [ -n "${missing_qps:-}" ]; then
    append_debt "$DEBTS" TDEBT "Peak QPS not provided — required to size infrastructure (Priority: 🟡 Important)" > /dev/null
fi
