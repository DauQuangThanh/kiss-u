#!/usr/bin/env bash
set -e
SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"
kiss_parse_standard_args "$@"
set -- "${KISS_REST_ARGS[@]}"
if [ "${1:-}" = "--help" ]; then echo "Usage: draft-deployment.sh [--auto]. Keys: DP_MODEL, DP_CANARY_BAKE_MIN, DP_ENVIRONMENTS."; exit 0; fi
read_context
SKILL_DIR="$(CDPATH="" cd "$SCRIPT_DIR/../.." && pwd)"
DIR="$KISS_REPO_ROOT/$KISS_DOCS_DIR/operations"
OUT="$DIR/deployment.md"
MODEL=$(resolve_auto DP_MODEL "canary") || true
BAKE=$(resolve_auto DP_CANARY_BAKE_MIN "30") || true
ENVS=$(resolve_auto DP_ENVIRONMENTS "dev,staging,prod") || true
if [ "${KISS_DRY_RUN:-0}" = "1" ]; then echo "[dry-run] model=$MODEL bake=$BAKE"; exit 0; fi
if [ -f "$OUT" ]; then echo "Deployment doc exists: $OUT" >&2; exit 2; fi
if ! confirm_before_write "Scaffold deployment doc at $OUT."; then echo "Aborted." >&2; exit 1; fi
mkdir -p "$DIR"
sed -e "s|{date}|$(date +%Y-%m-%d)|g" -e "s|{model}|$MODEL|g" -e "s|{bake_min}|$BAKE|g" -e "s|{envs}|$ENVS|g" \
    "$SKILL_DIR/templates/deployment-template.md" > "$OUT"
write_extract "$OUT" "MODEL=$MODEL" "BAKE_MIN=$BAKE" "ENVIRONMENTS=$ENVS" > /dev/null
echo "Wrote $OUT"
