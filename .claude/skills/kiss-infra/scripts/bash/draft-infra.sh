#!/usr/bin/env bash
set -e
SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"
kiss_parse_standard_args "$@"
set -- "${KISS_REST_ARGS[@]}"
if [ "${1:-}" = "--help" ]; then echo "Usage: draft-infra.sh [--auto]. Keys: INFRA_TOOL, INFRA_CLOUD, INFRA_ENVS."; exit 0; fi
read_context
SKILL_DIR="$(CDPATH="" cd "$SCRIPT_DIR/../.." && pwd)"
DIR="$KISS_REPO_ROOT/$KISS_DOCS_DIR/operations"
OUT="$DIR/infra.md"
TOOL=$(resolve_auto INFRA_TOOL "terraform") || true
CLOUD=$(resolve_auto INFRA_CLOUD "aws") || true
ENVS=$(resolve_auto INFRA_ENVS "dev,staging,prod") || true
if [ "${KISS_DRY_RUN:-0}" = "1" ]; then echo "[dry-run] would write: $OUT"; exit 0; fi
if [ -f "$OUT" ]; then echo "Infra doc exists: $OUT" >&2; exit 2; fi
if ! confirm_before_write "Scaffold infra doc at $OUT."; then echo "Aborted." >&2; exit 1; fi
mkdir -p "$DIR"
sed -e "s|{date}|$(date +%Y-%m-%d)|g" -e "s|{tool}|$TOOL|g" -e "s|{cloud}|$CLOUD|g" -e "s|{envs}|$ENVS|g" \
    "$SKILL_DIR/templates/infra-template.md" > "$OUT"
write_extract "$OUT" "TOOL=$TOOL" "CLOUD=$CLOUD" "ENVS=$ENVS" > /dev/null
echo "Wrote $OUT"
