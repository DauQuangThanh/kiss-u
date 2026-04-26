#!/usr/bin/env bash
set -e
SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"
kiss_parse_standard_args "$@"
set -- "${KISS_REST_ARGS[@]}"
if [ "${1:-}" = "--help" ]; then
    echo "Usage: audit.sh [--auto]. Keys: DA_LICENCE_POLICY, DA_MAX_AGE_DAYS."; exit 0
fi
read_context
SKILL_DIR="$(CDPATH="" cd "$SCRIPT_DIR/../.." && pwd)"
FEATURE="${KISS_CURRENT_FEATURE:-project}"
DIR="$KISS_REPO_ROOT/$KISS_DOCS_DIR/reviews/$FEATURE"
OUT="$DIR/dependencies.md"

POLICY=$(resolve_auto DA_LICENCE_POLICY "MIT,Apache-2.0,BSD-3-Clause,BSD-2-Clause,ISC") || true

# Detect lockfile
LOCKFILE=""
for f in uv.lock poetry.lock package-lock.json pnpm-lock.yaml yarn.lock go.sum Cargo.lock pom.xml Gemfile.lock mix.lock; do
    if [ -f "$KISS_REPO_ROOT/$f" ]; then LOCKFILE="$f"; break; fi
done
LOCKFILE="${LOCKFILE:-(none detected)}"

if [ "${KISS_DRY_RUN:-0}" = "1" ]; then echo "[dry-run] lockfile=$LOCKFILE  would write: $OUT"; exit 0; fi
if ! confirm_before_write "Scaffold dependency audit at $OUT."; then echo "Aborted." >&2; exit 1; fi
mkdir -p "$DIR"
if [ -f "$OUT" ]; then echo "Audit exists: $OUT (edit in place)." >&2; exit 2; fi

sed \
    -e "s|{feature}|$FEATURE|g" \
    -e "s|{date}|$(date +%Y-%m-%d)|g" \
    -e "s|{lockfile}|$LOCKFILE|g" \
    -e "s|{licence_policy}|$POLICY|g" \
    "$SKILL_DIR/templates/dependency-audit-template.md" > "$OUT"
write_extract "$OUT" "FEATURE=$FEATURE" "LOCKFILE=$LOCKFILE" "LICENCE_POLICY=$POLICY" > /dev/null
echo "Wrote $OUT — agent to enumerate deps from $LOCKFILE and fetch CVEs."
