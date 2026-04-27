#!/usr/bin/env bash
set -e
SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"
kiss_parse_standard_args "$@"
set -- "${KISS_REST_ARGS[@]}"

if [ "${1:-}" = "--help" ]; then
    cat <<'USAGE'
Usage: draft-uat.sh [--auto] [--answers FILE] [--dry-run] [--help]

Drafts the UAT plan and sign-off ledger for a feature.

Answer keys: UAT_FEATURE, UAT_ENV, UAT_START_DATE, UAT_END_DATE,
             UAT_CRITICAL_THRESHOLD, UAT_HIGH_THRESHOLD.
USAGE
    exit 0
fi

read_context

SKILL_DIR="$(CDPATH="" cd "$SCRIPT_DIR/../.." && pwd)"
DATE=$(date +%Y-%m-%d)

FEATURE=$(resolve_auto UAT_FEATURE "${KISS_CURRENT_FEATURE:-}") || true
if [ -z "$FEATURE" ]; then
    echo "ERROR: UAT_FEATURE is required (or set current.feature in .kiss/context.yml)." >&2
    exit 2
fi

UAT_ENV=$(resolve_auto UAT_ENV "staging") || true
START_DATE=$(resolve_auto UAT_START_DATE "") || true
END_DATE=$(resolve_auto UAT_END_DATE "") || true
HIGH_THRESHOLD=$(resolve_auto UAT_HIGH_THRESHOLD "3") || true

TEST_DIR=$(worktype_dir "testing")
FEATURE_DIR="$TEST_DIR/$FEATURE"
mkdir -p "$FEATURE_DIR"

OUT="$FEATURE_DIR/uat-plan.md"
SIGNOFF="$FEATURE_DIR/uat-sign-off.md"
DEBTS="$FEATURE_DIR/uat-debts.md"

if [ "${KISS_DRY_RUN:-0}" = "1" ]; then
    echo "[dry-run] would write: $OUT"
    echo "  feature=$FEATURE  env=$UAT_ENV  start=$START_DATE  end=$END_DATE"
    exit 0
fi

if ! confirm_before_write "Write UAT plan to $OUT."; then
    echo "Aborted." >&2
    exit 1
fi

cp "$SKILL_DIR/templates/uat-plan-template.md" "$OUT"
cp "$SKILL_DIR/templates/uat-sign-off-template.md" "$SIGNOFF"

sed -i.bak \
    -e "s|{feature}|$FEATURE|g" \
    -e "s|{revision}|1.0|g" \
    -e "s|{date}|$DATE|g" \
    -e "s|{uat_env}|$UAT_ENV|g" \
    -e "s|{start_date}|${START_DATE:-TBD}|g" \
    -e "s|{end_date}|${END_DATE:-TBD}|g" \
    -e "s|{high_threshold}|$HIGH_THRESHOLD|g" \
    -e "s|{scenarios}|<!-- AI: populate UAT scenarios from spec.md user stories -->|g" \
    -e "s|{in_scope}|<!-- AI: populate from spec.md scope -->|g" \
    -e "s|{out_scope}|<!-- AI: populate from spec.md out-of-scope -->|g" \
    -e "s|{test_data_policy}|Representative synthetic data|g" \
    -e "s|{data_refresh}|Before each UAT session|g" \
    -e "s|{user_rep_count}|3–5|g" \
    -e "s|{sme_count}|1–2|g" \
    "$OUT" && rm -f "$OUT.bak"

sed -i.bak \
    -e "s|{feature}|$FEATURE|g" \
    -e "s|{date}|$DATE|g" \
    -e "s|{start_date}|${START_DATE:-TBD}|g" \
    -e "s|{end_date}|${END_DATE:-TBD}|g" \
    -e "s|{total_scenarios}|0|g" \
    -e "s|{passed}|0|g" \
    -e "s|{failed}|0|g" \
    -e "s|{not_run}|0|g" \
    -e "s|{open_critical}|0|g" \
    -e "s|{open_high}|0|g" \
    "$SIGNOFF" && rm -f "$SIGNOFF.bak"

write_extract "$OUT" \
    "UAT_REVISION=1.0" \
    "UAT_FEATURE=$FEATURE" \
    "UAT_ENV=$UAT_ENV" \
    "UAT_START_DATE=${START_DATE:-TBD}" \
    "UAT_END_DATE=${END_DATE:-TBD}" \
    "UAT_HIGH_THRESHOLD=$HIGH_THRESHOLD" > /dev/null

echo "Wrote $OUT"
echo "Wrote $SIGNOFF"
