#!/usr/bin/env bash
set -e
SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"
kiss_parse_standard_args "$@"
set -- "${KISS_REST_ARGS[@]}"
if [ "${1:-}" = "--help" ]; then echo "Usage: draft-monitoring.sh [--auto]. Keys: MON_STACK, MON_SLO_AVAILABILITY, MON_SLO_P95_MS."; exit 0; fi
read_context
SKILL_DIR="$(CDPATH="" cd "$SCRIPT_DIR/../.." && pwd)"
DIR="$KISS_REPO_ROOT/$KISS_DOCS_DIR/operations"
OUT="$DIR/monitoring.md"
STACK=$(resolve_auto MON_STACK "otel") || true
AVAIL=$(resolve_auto MON_SLO_AVAILABILITY "99.9") || true
P95=$(resolve_auto MON_SLO_P95_MS "300") || true
if [ "${KISS_DRY_RUN:-0}" = "1" ]; then echo "[dry-run] stack=$STACK slo=$AVAIL/$P95"; exit 0; fi
if [ -f "$OUT" ]; then echo "Monitoring doc exists: $OUT" >&2; exit 2; fi
if ! confirm_before_write "Scaffold monitoring doc at $OUT."; then echo "Aborted." >&2; exit 1; fi
mkdir -p "$DIR"
sed -e "s|{date}|$(date +%Y-%m-%d)|g" -e "s|{stack}|$STACK|g" -e "s|{slo_avail}|$AVAIL|g" -e "s|{slo_p95_ms}|$P95|g" \
    "$SKILL_DIR/templates/monitoring-template.md" > "$OUT"
write_extract "$OUT" "STACK=$STACK" "SLO_AVAILABILITY=$AVAIL" "SLO_P95_MS=$P95" > /dev/null
echo "Wrote $OUT"
