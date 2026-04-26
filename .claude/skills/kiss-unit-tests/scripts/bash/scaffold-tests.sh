#!/usr/bin/env bash
# kiss-unit-tests: scaffold the index file. Actual test files are
# written by the agent via its Write tool — this script only sets up
# the tracking artefact and default env.
set -e
SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"
kiss_parse_standard_args "$@"
set -- "${KISS_REST_ARGS[@]}"

if [ "${1:-}" = "--help" ]; then
    cat <<'USAGE'
Usage: scaffold-tests.sh [--auto] [--dry-run]
Scaffolds the unit-tests index at
  docs/testing/<feature>/unit-tests-index.md.
The agent fills in per-module test skeletons separately.
Answer keys: UT_FRAMEWORK, UT_TARGET_DIR, UT_MIN_COVERAGE.
USAGE
    exit 0
fi

read_context
SKILL_DIR="$(CDPATH="" cd "$SCRIPT_DIR/../.." && pwd)"

if [ -z "${KISS_CURRENT_FEATURE:-}" ]; then
    echo "ERROR: current.feature required." >&2; exit 2
fi
DIR=$(feature_scoped_dir testing)
DEBTS="$DIR/test-debts.md"

# Detect framework
FW=""
TGT=""
if [ -f "$KISS_REPO_ROOT/pyproject.toml" ] || [ -f "$KISS_REPO_ROOT/pytest.ini" ]; then
    FW="pytest"; TGT="tests"
elif [ -f "$KISS_REPO_ROOT/package.json" ]; then
    if grep -q '"vitest"' "$KISS_REPO_ROOT/package.json" 2>/dev/null; then FW="vitest"; TGT="tests"
    elif grep -q '"jest"' "$KISS_REPO_ROOT/package.json" 2>/dev/null; then FW="jest"; TGT="__tests__"
    elif grep -q '"mocha"' "$KISS_REPO_ROOT/package.json" 2>/dev/null; then FW="mocha"; TGT="test"
    fi
elif [ -f "$KISS_REPO_ROOT/go.mod" ]; then FW="go-test"; TGT="(co-located)"
elif [ -f "$KISS_REPO_ROOT/Cargo.toml" ]; then FW="cargo-test"; TGT="tests"
elif ls "$KISS_REPO_ROOT"/*.csproj >/dev/null 2>&1; then FW="xunit"; TGT="<proj>.Tests"
elif [ -f "$KISS_REPO_ROOT/pom.xml" ] || ls "$KISS_REPO_ROOT"/build.gradle* >/dev/null 2>&1; then FW="junit5"; TGT="src/test/java"
elif [ -f "$KISS_REPO_ROOT/Gemfile" ]; then FW="rspec"; TGT="spec"
elif [ -f "$KISS_REPO_ROOT/mix.exs" ]; then FW="exunit"; TGT="test"
fi

FW_RESOLVED=$(resolve_auto UT_FRAMEWORK "${FW:-unknown}") || true
TGT_RESOLVED=$(resolve_auto UT_TARGET_DIR "${TGT:-tests}") || true
COV=$(resolve_auto UT_MIN_COVERAGE "80") || true

OUT="$DIR/unit-tests-index.md"

if [ "${KISS_DRY_RUN:-0}" = "1" ]; then
    echo "[dry-run] would write: $OUT"
    echo "  framework=$FW_RESOLVED target=$TGT_RESOLVED min_coverage=$COV"
    exit 0
fi

if [ -f "$OUT" ]; then echo "Index exists: $OUT" >&2; exit 2; fi
if ! confirm_before_write "Scaffold unit-tests index at $OUT."; then echo "Aborted." >&2; exit 1; fi

sed \
    -e "s|{feature}|$KISS_CURRENT_FEATURE|g" \
    -e "s|{date}|$(date +%Y-%m-%d)|g" \
    -e "s|{framework}|$FW_RESOLVED|g" \
    -e "s|{target_dir}|$TGT_RESOLVED|g" \
    -e "s|{min_coverage}|$COV|g" \
    "$SKILL_DIR/templates/unit-tests-index-template.md" > "$OUT"

write_extract "$OUT" "FEATURE=$KISS_CURRENT_FEATURE" "FRAMEWORK=$FW_RESOLVED" "TARGET_DIR=$TGT_RESOLVED" "MIN_COVERAGE=$COV" > /dev/null
echo "Wrote $OUT"

if [ "$FW_RESOLVED" = "unknown" ]; then
    append_debt "$DEBTS" TQDEBT "Unit-test framework could not be detected — developer must choose one (Priority: 🟡 Important)" > /dev/null
fi
