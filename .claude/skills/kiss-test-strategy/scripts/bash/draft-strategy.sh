#!/usr/bin/env bash
set -e
SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"
kiss_parse_standard_args "$@"
set -- "${KISS_REST_ARGS[@]}"
if [ "${1:-}" = "--help" ]; then
    cat <<'USAGE'
Usage: draft-strategy.sh [--auto] [--dry-run]
Scaffolds docs/testing/<feature>/strategy.md.
Keys: TS_RISK_TIERS, TS_LEVELS, TS_ENVIRONMENTS, TS_COVERAGE_TARGET.
USAGE
    exit 0
fi
read_context
SKILL_DIR="$(CDPATH="" cd "$SCRIPT_DIR/../.." && pwd)"
if [ -z "${KISS_CURRENT_FEATURE:-}" ]; then echo "ERROR: current.feature required" >&2; exit 2; fi
DIR=$(feature_scoped_dir testing)
OUT="$DIR/strategy.md"

TIERS=$(resolve_auto TS_RISK_TIERS "high,medium,low") || true
LEVELS=$(resolve_auto TS_LEVELS "unit,integration,e2e") || true
ENVS=$(resolve_auto TS_ENVIRONMENTS "dev,staging,prod") || true
COV=$(resolve_auto TS_COVERAGE_TARGET "80") || true

if [ "${KISS_DRY_RUN:-0}" = "1" ]; then echo "[dry-run] would write: $OUT"; exit 0; fi
if [ -f "$OUT" ]; then echo "Strategy exists: $OUT" >&2; exit 2; fi
if ! confirm_before_write "Scaffold test strategy at $OUT."; then echo "Aborted." >&2; exit 1; fi

sed \
    -e "s|{feature}|$KISS_CURRENT_FEATURE|g" \
    -e "s|{date}|$(date +%Y-%m-%d)|g" \
    -e "s|{risk_tiers}|$TIERS|g" \
    -e "s|{environments}|$ENVS|g" \
    -e "s|{coverage_target}|$COV|g" \
    "$SKILL_DIR/templates/strategy-template.md" > "$OUT"

write_extract "$OUT" "FEATURE=$KISS_CURRENT_FEATURE" "LEVELS=$LEVELS" "RISK_TIERS=$TIERS" "ENVIRONMENTS=$ENVS" "COVERAGE_TARGET=$COV" > /dev/null
echo "Wrote $OUT"
