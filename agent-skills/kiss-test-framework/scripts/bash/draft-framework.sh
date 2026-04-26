#!/usr/bin/env bash
set -e
SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"
kiss_parse_standard_args "$@"
set -- "${KISS_REST_ARGS[@]}"
if [ "${1:-}" = "--help" ]; then
    cat <<'USAGE'
Usage: draft-framework.sh [--auto] [--dry-run]
Scaffolds docs/testing/<feature>/framework.md.
Keys: TF_UNIT_FRAMEWORK, TF_INTEGRATION_FRAMEWORK, TF_E2E_FRAMEWORK.
USAGE
    exit 0
fi
read_context
SKILL_DIR="$(CDPATH="" cd "$SCRIPT_DIR/../.." && pwd)"
if [ -z "${KISS_CURRENT_FEATURE:-}" ]; then echo "ERROR: current.feature required" >&2; exit 2; fi
DIR=$(feature_scoped_dir testing)
OUT="$DIR/framework.md"

# Detect
UNIT_DETECT=""
if [ -f "$KISS_REPO_ROOT/pyproject.toml" ]; then UNIT_DETECT="pytest"
elif [ -f "$KISS_REPO_ROOT/package.json" ]; then
    if grep -q '"vitest"' "$KISS_REPO_ROOT/package.json" 2>/dev/null; then UNIT_DETECT="vitest"
    elif grep -q '"jest"' "$KISS_REPO_ROOT/package.json" 2>/dev/null; then UNIT_DETECT="jest"
    elif grep -q '"mocha"' "$KISS_REPO_ROOT/package.json" 2>/dev/null; then UNIT_DETECT="mocha"
    else UNIT_DETECT="vitest"
    fi
elif [ -f "$KISS_REPO_ROOT/go.mod" ]; then UNIT_DETECT="go-test"
elif [ -f "$KISS_REPO_ROOT/Cargo.toml" ]; then UNIT_DETECT="cargo-test"
elif [ -f "$KISS_REPO_ROOT/pom.xml" ]; then UNIT_DETECT="junit5"
fi

UNIT=$(resolve_auto TF_UNIT_FRAMEWORK "${UNIT_DETECT:-pytest}") || true
INTEG=$(resolve_auto TF_INTEGRATION_FRAMEWORK "$UNIT") || true
E2E=$(resolve_auto TF_E2E_FRAMEWORK "playwright") || true

if [ "${KISS_DRY_RUN:-0}" = "1" ]; then echo "[dry-run] unit=$UNIT integ=$INTEG e2e=$E2E"; exit 0; fi
if [ -f "$OUT" ]; then echo "Framework doc exists: $OUT" >&2; exit 2; fi
if ! confirm_before_write "Scaffold framework doc at $OUT."; then echo "Aborted." >&2; exit 1; fi

sed \
    -e "s|{feature}|$KISS_CURRENT_FEATURE|g" \
    -e "s|{date}|$(date +%Y-%m-%d)|g" \
    -e "s|{unit}|$UNIT|g" \
    -e "s|{integration}|$INTEG|g" \
    -e "s|{e2e}|$E2E|g" \
    "$SKILL_DIR/templates/framework-template.md" > "$OUT"
write_extract "$OUT" "UNIT=$UNIT" "INTEGRATION=$INTEG" "E2E=$E2E" > /dev/null
echo "Wrote $OUT"
