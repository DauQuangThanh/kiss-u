#!/usr/bin/env bash
# kiss-risk-register: append one risk entry to the project's risk
# register. Creates the register from the template if absent.

set -e

SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

kiss_parse_standard_args "$@"
set -- "${KISS_REST_ARGS[@]}"

if [ "${1:-}" = "--help" ]; then
    cat <<'USAGE'
Usage: add-risk.sh [--auto] [--answers FILE] [--dry-run] [--help]

Appends one risk entry to docs/project/risk-register.md.

Answer keys:
  RISK_DESCRIPTION  one-line risk description (required)
  RISK_CATEGORY     Technical|Schedule|Resource|Budget|Scope|External|Other (default: Other)
  RISK_LIKELIHOOD   1-5 (default: 3)
  RISK_IMPACT       1-5 (default: 3)
  RISK_OWNER        name or role (required)
  RISK_MITIGATION   what reduces likelihood/impact (required)
  RISK_CONTINGENCY  backup plan (optional)
  RISK_STATUS       Active|Mitigated|Closed (default: Active)
USAGE
    exit 0
fi

read_context

SKILL_DIR="$(CDPATH="" cd "$SCRIPT_DIR/../.." && pwd)"
PROJECT_DIR="$KISS_REPO_ROOT/$KISS_DOCS_DIR/project"
REGISTER="$PROJECT_DIR/risk-register.md"
EXTRACT="$PROJECT_DIR/risk-register.extract"
DEBTS_FILE="$PROJECT_DIR/pm-debts.md"

DESCRIPTION=$(resolve_auto RISK_DESCRIPTION "") || missing_desc=1
CATEGORY=$(resolve_auto RISK_CATEGORY "Other") || true
LIKELIHOOD=$(resolve_auto RISK_LIKELIHOOD "3") || true
IMPACT=$(resolve_auto RISK_IMPACT "3") || true
OWNER=$(resolve_auto RISK_OWNER "") || missing_owner=1
MITIGATION=$(resolve_auto RISK_MITIGATION "") || missing_mitigation=1
CONTINGENCY=$(resolve_auto RISK_CONTINGENCY "") || true
STATUS=$(resolve_auto RISK_STATUS "Active") || true

# Score + band
case "$LIKELIHOOD" in 1|2|3|4|5) ;; *) LIKELIHOOD=3 ;; esac
case "$IMPACT" in 1|2|3|4|5) ;; *) IMPACT=3 ;; esac
SCORE=$((LIKELIHOOD * IMPACT))
if [ "$SCORE" -ge 15 ]; then BAND="🔴 Red"
elif [ "$SCORE" -ge 8 ]; then BAND="🟡 Amber"
else BAND="🟢 Green"
fi

if [ "${KISS_DRY_RUN:-0}" = "1" ]; then
    echo "[dry-run] would append risk to: $REGISTER"
    echo "[dry-run] description:   ${DESCRIPTION:-<missing>}"
    echo "[dry-run] category:      $CATEGORY"
    echo "[dry-run] likelihood:    $LIKELIHOOD"
    echo "[dry-run] impact:        $IMPACT"
    echo "[dry-run] score/band:    $SCORE  $BAND"
    echo "[dry-run] owner:         ${OWNER:-<missing>}"
    echo "[dry-run] mitigation:    ${MITIGATION:-<missing>}"
    echo "[dry-run] status:        $STATUS"
    exit 0
fi

if ! confirm_before_write "Append risk to $REGISTER."; then
    echo "Aborted." >&2
    exit 1
fi

mkdir -p "$PROJECT_DIR"

# Bootstrap the register from template on first use.
if [ ! -f "$REGISTER" ]; then
    TEMPLATE="$SKILL_DIR/templates/risk-register-template.md"
    PROJECT_NAME="${KISS_CURRENT_FEATURE:-project}"
    # Try to read PROJECT_NAME from the plan's extract.
    if [ -f "$PROJECT_DIR/project-plan.extract" ]; then
        _p=$(grep -E '^PROJECT_NAME=' "$PROJECT_DIR/project-plan.extract" | head -n1 | cut -d= -f2-)
        [ -n "$_p" ] && PROJECT_NAME="$_p"
    fi
    sed \
        -e "s|{project_name}|$PROJECT_NAME|g" \
        -e "s|{date}|$(date +%Y-%m-%d)|g" \
        -e "s|{feature}|${KISS_CURRENT_FEATURE:-<none>}|g" \
        "$TEMPLATE" > "$REGISTER"
    # Remove the single placeholder RISK-NN block the template ships with;
    # every real entry will be appended below.
    awk 'BEGIN{skip=0} /^### RISK-NN:/{skip=1} skip && /^---$/{skip=0; next} !skip' "$REGISTER" > "$REGISTER.tmp"
    mv "$REGISTER.tmp" "$REGISTER"
fi

# Next id
NEXT=1
last=$(grep -Eo '^### RISK-[0-9]+' "$REGISTER" 2>/dev/null | grep -Eo '[0-9]+$' | sort -n | tail -n1 || true)
if [ -n "$last" ]; then NEXT=$((10#$last + 1)); fi
RID=$(printf 'RISK-%02d' "$NEXT")

{
    printf '\n### %s: %s\n\n' "$RID" "${DESCRIPTION:-<TBD>}"
    printf '**Category:** %s\n' "$CATEGORY"
    printf '**Likelihood:** %s/5\n' "$LIKELIHOOD"
    printf '**Impact:** %s/5\n' "$IMPACT"
    printf '**Score:** %s (%s)\n' "$SCORE" "$BAND"
    printf '**Description:** %s\n' "${DESCRIPTION:-<TBD>}"
    printf '**Mitigation:** %s\n' "${MITIGATION:-<TBD>}"
    printf '**Contingency:** %s\n' "${CONTINGENCY:-<none>}"
    printf '**Owner:** %s\n' "${OWNER:-<TBD>}"
    printf '**Status:** %s\n' "$STATUS"
    printf '**Last updated:** %s\n\n---\n' "$(date +%Y-%m-%d)"
} >> "$REGISTER"

# Recompute band counts for the .extract.
# Match the parenthesised band marker; avoid ".*" before the emoji
# because some grep builds mis-handle multi-byte ranges there.
RED=$(grep -c '(🔴 Red)' "$REGISTER" 2>/dev/null)   || true
AMBER=$(grep -c '(🟡 Amber)' "$REGISTER" 2>/dev/null) || true
GREEN=$(grep -c '(🟢 Green)' "$REGISTER" 2>/dev/null) || true
TOTAL=$(grep -c '^### RISK-' "$REGISTER" 2>/dev/null) || true
RED=${RED:-0}; AMBER=${AMBER:-0}; GREEN=${GREEN:-0}; TOTAL=${TOTAL:-0}

write_extract "$REGISTER" \
    "TOTAL_RISKS=$TOTAL" \
    "RED=$RED" \
    "AMBER=$AMBER" \
    "GREEN=$GREEN" \
    "LAST_ADDED=$RID" > /dev/null

echo "Appended $RID ($SCORE $BAND) to $REGISTER"

# Debts for missing required inputs
if [ -n "${missing_desc:-}" ]; then
    append_debt "$DEBTS_FILE" PMDEBT "Risk $RID has no description (Area: Risk, Owner: user, Priority: 🔴 Blocking)" > /dev/null
fi
if [ -n "${missing_owner:-}" ]; then
    append_debt "$DEBTS_FILE" PMDEBT "Risk $RID has no owner (Area: Risk, Owner: user, Priority: 🟡 Important)" > /dev/null
fi
if [ -n "${missing_mitigation:-}" ]; then
    append_debt "$DEBTS_FILE" PMDEBT "Risk $RID has no mitigation plan (Area: Risk, Owner: user, Priority: 🟡 Important)" > /dev/null
fi
