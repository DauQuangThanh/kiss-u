#!/usr/bin/env bash
set -e
SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"
kiss_parse_standard_args "$@"
set -- "${KISS_REST_ARGS[@]}"
if [ "${1:-}" = "--help" ]; then
    echo "Usage: draft-cicd.sh [--auto]. Keys: CI_PROVIDER, CI_REQUIRES_MANUAL_RELEASE."; exit 0
fi
read_context
SKILL_DIR="$(CDPATH="" cd "$SCRIPT_DIR/../.." && pwd)"
DIR="$KISS_REPO_ROOT/$KISS_DOCS_DIR/operations"
OUT="$DIR/cicd.md"
PROV=$(resolve_auto CI_PROVIDER "github-actions") || true
MANUAL=$(resolve_auto CI_REQUIRES_MANUAL_RELEASE "true") || true

if [ "${KISS_DRY_RUN:-0}" = "1" ]; then echo "[dry-run] would write: $OUT"; exit 0; fi
if [ -f "$OUT" ]; then echo "CI/CD doc exists: $OUT" >&2; exit 2; fi
if ! confirm_before_write "Scaffold CI/CD doc at $OUT."; then echo "Aborted." >&2; exit 1; fi
mkdir -p "$DIR"
sed -e "s|{date}|$(date +%Y-%m-%d)|g" -e "s|{provider}|$PROV|g" -e "s|{manual_release}|$MANUAL|g" \
    "$SKILL_DIR/templates/cicd-template.md" > "$OUT"
write_extract "$OUT" "PROVIDER=$PROV" "MANUAL_RELEASE=$MANUAL" > /dev/null
echo "Wrote $OUT"
