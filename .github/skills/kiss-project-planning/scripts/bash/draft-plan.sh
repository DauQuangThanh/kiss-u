#!/usr/bin/env bash
# kiss-pm-planning: scaffold the project plan artefact under
# docs/project/project-plan.md, optionally producing a companion
# communication-plan.md. Templates are copied; the AI prompt is
# what fills in the content.

set -e

SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

kiss_parse_standard_args "$@"
set -- "${KISS_REST_ARGS[@]}"

if [ "${1:-}" = "--help" ]; then
    cat <<'USAGE'
Usage: draft-plan.sh [--auto] [--answers FILE] [--dry-run] [--help]

Scaffolds the project plan artefact at docs/project/project-plan.md
from templates/project-plan-template.md. When PM_INCLUDE_COMMS_PLAN=true
(or provided interactively), also scaffolds docs/project/communication-plan.md.

Resolves these keys from env / answers-file / .extract:
  PM_PROJECT_NAME        (default: derived from current.feature)
  PM_METHODOLOGY         (default: scrum)
  PM_START_DATE          (default: today)
  PM_TARGET_GO_LIVE      (no default — logs a debt if missing)
  PM_TEAM_SIZE           (no default — logs a debt if missing)
  PM_SPONSOR             (no default — logs a debt if missing)
  PM_INCLUDE_COMMS_PLAN  (default: false)

After the artefact is written, the kiss-pm-planning.md prompt instructs
the agent to flesh out the sections interactively with the user.
USAGE
    exit 0
fi

read_context

SKILL_DIR="$(CDPATH="" cd "$SCRIPT_DIR/../.." && pwd)"
PROJECT_DIR="$KISS_REPO_ROOT/$KISS_DOCS_DIR/project"
PLAN_FILE="$PROJECT_DIR/project-plan.md"
COMMS_FILE="$PROJECT_DIR/communication-plan.md"
DEBTS_FILE="$PROJECT_DIR/pm-debts.md"

# Resolve answer keys. A debt is logged whenever a required input
# is missing and --auto is in effect.
PROJECT_NAME=$(resolve_auto PM_PROJECT_NAME "${KISS_CURRENT_FEATURE:-project}") || true
METHODOLOGY=$(resolve_auto PM_METHODOLOGY "scrum") || defaulted_methodology=1
START_DATE=$(resolve_auto PM_START_DATE "$(date +%Y-%m-%d)") || true
TARGET_GO_LIVE=$(resolve_auto PM_TARGET_GO_LIVE "") || missing_go_live=1
TEAM_SIZE=$(resolve_auto PM_TEAM_SIZE "") || missing_team_size=1
SPONSOR=$(resolve_auto PM_SPONSOR "") || missing_sponsor=1
INCLUDE_COMMS=$(resolve_auto PM_INCLUDE_COMMS_PLAN "false") || true

if [ "${KISS_DRY_RUN:-0}" = "1" ]; then
    echo "[dry-run] would write: $PLAN_FILE"
    if [ "$INCLUDE_COMMS" = "true" ]; then
        echo "[dry-run] would write: $COMMS_FILE"
    fi
    echo "[dry-run] project_name:    $PROJECT_NAME"
    echo "[dry-run] methodology:     $METHODOLOGY"
    echo "[dry-run] start_date:      $START_DATE"
    echo "[dry-run] target_go_live:  ${TARGET_GO_LIVE:-<missing>}"
    echo "[dry-run] team_size:       ${TEAM_SIZE:-<missing>}"
    echo "[dry-run] sponsor:         ${SPONSOR:-<missing>}"
    echo "[dry-run] include_comms:   $INCLUDE_COMMS"
    exit 0
fi

if ! confirm_before_write "Scaffold project plan at $PLAN_FILE."; then
    echo "Aborted." >&2
    exit 1
fi

mkdir -p "$PROJECT_DIR"

if [ -f "$PLAN_FILE" ]; then
    echo "Project plan already exists: $PLAN_FILE"
    echo "Refusing to overwrite. Edit in place or remove the file first." >&2
    exit 2
fi

# Copy template and substitute the trivial placeholders. The agent
# fills in the rest based on the kiss-pm-planning.md prompt.
TEMPLATE="$SKILL_DIR/templates/project-plan-template.md"
sed \
    -e "s|{project_name}|$PROJECT_NAME|g" \
    -e "s|{date}|$START_DATE|g" \
    -e "s|{methodology}|$METHODOLOGY|g" \
    -e "s|{sponsor}|${SPONSOR:-<TBD>}|g" \
    -e "s|{feature}|${KISS_CURRENT_FEATURE:-<none>}|g" \
    "$TEMPLATE" > "$PLAN_FILE"

write_extract "$PLAN_FILE" \
    "PROJECT_NAME=$PROJECT_NAME" \
    "METHODOLOGY=$METHODOLOGY" \
    "START_DATE=$START_DATE" \
    "TARGET_GO_LIVE=$TARGET_GO_LIVE" \
    "TEAM_SIZE=$TEAM_SIZE" \
    "SPONSOR=$SPONSOR" > /dev/null

echo "Wrote $PLAN_FILE"

# Optional companion
if [ "$INCLUDE_COMMS" = "true" ]; then
    COMMS_TEMPLATE="$SKILL_DIR/templates/communication-plan-template.md"
    sed \
        -e "s|{project_name}|$PROJECT_NAME|g" \
        -e "s|{date}|$START_DATE|g" \
        "$COMMS_TEMPLATE" > "$COMMS_FILE"
    echo "Wrote $COMMS_FILE"
fi

# Log debts for any required input that fell back to a default.
if [ -n "${missing_go_live:-}" ]; then
    append_debt "$DEBTS_FILE" PMDEBT "Target go-live date is not set — required to compute critical path (Area: Schedule, Owner: user, Priority: 🔴 Blocking)" > /dev/null
fi
if [ -n "${missing_team_size:-}" ]; then
    append_debt "$DEBTS_FILE" PMDEBT "Team size is not set — required to estimate capacity (Area: Resource, Owner: user, Priority: 🟡 Important)" > /dev/null
fi
if [ -n "${missing_sponsor:-}" ]; then
    append_debt "$DEBTS_FILE" PMDEBT "Project sponsor is not set — required for escalation path (Area: Stakeholders, Owner: user, Priority: 🟡 Important)" > /dev/null
fi
if [ -n "${defaulted_methodology:-}" ]; then
    append_debt "$DEBTS_FILE" PMDEBT "Methodology defaulted to 'scrum' — confirm with user (Area: Integration, Owner: user, Priority: 🟢 Can wait)" > /dev/null
fi

if [ -f "$DEBTS_FILE" ]; then
    echo "Logged debts to $DEBTS_FILE (review before finalising the plan)."
fi
