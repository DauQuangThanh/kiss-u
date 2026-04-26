#!/usr/bin/env bash
set -e
SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"
kiss_parse_standard_args "$@"
set -- "${KISS_REST_ARGS[@]}"
if [ "${1:-}" = "--help" ]; then
    echo "Usage: draft-gates.sh [--auto]. Keys: QG_COVERAGE_PR, QG_COVERAGE_RELEASE, QG_P95_MS, QG_MAX_HIGH_VULN, QG_MAX_CRIT_VULN."
    exit 0
fi
read_context
SKILL_DIR="$(CDPATH="" cd "$SCRIPT_DIR/../.." && pwd)"
if [ -z "${KISS_CURRENT_FEATURE:-}" ]; then echo "ERROR: current.feature required" >&2; exit 2; fi
DIR=$(feature_scoped_dir testing)
OUT="$DIR/quality-gates.md"

CP=$(resolve_auto QG_COVERAGE_PR "80") || true
CR=$(resolve_auto QG_COVERAGE_RELEASE "85") || true
P95=$(resolve_auto QG_P95_MS "200") || true
MH=$(resolve_auto QG_MAX_HIGH_VULN "0") || true
MC=$(resolve_auto QG_MAX_CRIT_VULN "0") || true

if [ "${KISS_DRY_RUN:-0}" = "1" ]; then echo "[dry-run] would write: $OUT"; exit 0; fi
if [ -f "$OUT" ]; then echo "Gates doc exists: $OUT" >&2; exit 2; fi
if ! confirm_before_write "Scaffold quality gates at $OUT."; then echo "Aborted." >&2; exit 1; fi

sed \
    -e "s|{feature}|$KISS_CURRENT_FEATURE|g" \
    -e "s|{date}|$(date +%Y-%m-%d)|g" \
    -e "s|{cov_pr}|$CP|g" \
    -e "s|{cov_release}|$CR|g" \
    -e "s|{p95_ms}|$P95|g" \
    -e "s|{max_high}|$MH|g" \
    -e "s|{max_crit}|$MC|g" \
    "$SKILL_DIR/templates/gates-template.md" > "$OUT"
write_extract "$OUT" "COVERAGE_PR=$CP" "COVERAGE_RELEASE=$CR" "P95_MS=$P95" "MAX_HIGH_VULN=$MH" "MAX_CRIT_VULN=$MC" > /dev/null
echo "Wrote $OUT"
