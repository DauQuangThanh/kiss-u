#!/usr/bin/env bash
set -e
SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"
kiss_parse_standard_args "$@"
set -- "${KISS_REST_ARGS[@]}"
if [ "${1:-}" = "--help" ]; then echo "Usage: draft-containers.sh [--auto]. Keys: CONT_RUNTIME, CONT_BASE_IMAGE."; exit 0; fi
read_context
SKILL_DIR="$(CDPATH="" cd "$SCRIPT_DIR/../.." && pwd)"
DIR="$KISS_REPO_ROOT/$KISS_DOCS_DIR/operations"
OUT="$DIR/containers.md"

RUNTIME_DETECT="unknown"
if [ -f "$KISS_REPO_ROOT/package.json" ]; then RUNTIME_DETECT="node"
elif [ -f "$KISS_REPO_ROOT/pyproject.toml" ] || [ -f "$KISS_REPO_ROOT/requirements.txt" ]; then RUNTIME_DETECT="python"
elif [ -f "$KISS_REPO_ROOT/go.mod" ]; then RUNTIME_DETECT="go"
elif [ -f "$KISS_REPO_ROOT/Cargo.toml" ]; then RUNTIME_DETECT="rust"
elif [ -f "$KISS_REPO_ROOT/pom.xml" ]; then RUNTIME_DETECT="java"
fi

RUNTIME=$(resolve_auto CONT_RUNTIME "$RUNTIME_DETECT") || true
BASE=$(resolve_auto CONT_BASE_IMAGE "slim") || true

if [ "${KISS_DRY_RUN:-0}" = "1" ]; then echo "[dry-run] runtime=$RUNTIME base=$BASE"; exit 0; fi
if [ -f "$OUT" ]; then echo "Containers doc exists: $OUT" >&2; exit 2; fi
if ! confirm_before_write "Scaffold containers doc at $OUT."; then echo "Aborted." >&2; exit 1; fi
mkdir -p "$DIR"
sed -e "s|{date}|$(date +%Y-%m-%d)|g" -e "s|{runtime}|$RUNTIME|g" -e "s|{base_image}|$BASE|g" \
    "$SKILL_DIR/templates/containers-template.md" > "$OUT"
write_extract "$OUT" "RUNTIME=$RUNTIME" "BASE_IMAGE=$BASE" > /dev/null
echo "Wrote $OUT"
