#!/usr/bin/env bash
set -e
SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"
kiss_parse_standard_args "$@"
set -- "${KISS_REST_ARGS[@]}"
if [ "${1:-}" = "--help" ]; then
    echo "Usage: review.sh [--auto]. Keys: SR_SCOPE, SR_COMPLIANCE, SR_THREAT_MODEL."; exit 0
fi
read_context
SKILL_DIR="$(CDPATH="" cd "$SCRIPT_DIR/../.." && pwd)"
if [ -z "${KISS_CURRENT_FEATURE:-}" ]; then echo "ERROR: current.feature required" >&2; exit 2; fi
DIR=$(feature_scoped_dir reviews)
OUT="$DIR/security.md"

SCOPE=$(resolve_auto SR_SCOPE "src/**") || true
COMP=$(resolve_auto SR_COMPLIANCE "") || true
TM=$(resolve_auto SR_THREAT_MODEL "stride") || true

# Build compliance notes (multi-line string).
COMP_NOTES=""
if [ -n "$COMP" ]; then
    IFS=',' read -ra C <<< "$COMP"
    for r in "${C[@]}"; do
        trimmed="$(echo "$r" | awk '{$1=$1;print}')"
        COMP_NOTES+="- **$trimmed** — review data flow for applicable controls."$'\n'
    done
else
    COMP_NOTES="- (none specified)"$'\n'
fi

if [ "${KISS_DRY_RUN:-0}" = "1" ]; then echo "[dry-run] would write: $OUT"; exit 0; fi
if [ -f "$OUT" ]; then echo "Security review exists: $OUT" >&2; exit 2; fi
if ! confirm_before_write "Scaffold security review at $OUT."; then echo "Aborted." >&2; exit 1; fi

# Render via awk — simple gsub for single-line placeholders, slurp file
# for the one multi-line placeholder {compliance_notes}.
TPL="$SKILL_DIR/templates/security-review-template.md"
DATE_V="$(date +%Y-%m-%d)"
COMP_DISPLAY="${COMP:-none}"

NOTES_FILE="$(mktemp -t kiss-comp.XXXXXX)"
printf '%s' "$COMP_NOTES" > "$NOTES_FILE"

awk -v feature="$KISS_CURRENT_FEATURE" \
    -v datev="$DATE_V" \
    -v scope="$SCOPE" \
    -v comp="$COMP_DISPLAY" \
    -v tm="$TM" \
    -v notesfile="$NOTES_FILE" '
    function slurp(f,   line, out) {
        while ((getline line < f) > 0) { out = out line "\n" }
        close(f)
        return out
    }
    {
        gsub(/\{feature\}/, feature)
        gsub(/\{date\}/, datev)
        gsub(/\{scope\}/, scope)
        gsub(/\{compliance\}/, comp)
        gsub(/\{threat_model\}/, tm)
        if (index($0, "{compliance_notes}")) {
            sub(/\{compliance_notes\}/, slurp(notesfile))
        }
        print
    }
' "$TPL" > "$OUT"

rm -f "$NOTES_FILE"

write_extract "$OUT" "FEATURE=$KISS_CURRENT_FEATURE" "SCOPE=$SCOPE" "COMPLIANCE=$COMP" "THREAT_MODEL=$TM" > /dev/null
echo "Wrote $OUT"
