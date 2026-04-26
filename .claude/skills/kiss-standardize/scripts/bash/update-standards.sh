#!/usr/bin/env bash
# kiss-standardize: scaffold or update the project standards file.

set -e

SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

kiss_parse_standard_args "$@"
set -- "${KISS_REST_ARGS[@]}"

if [ "${1:-}" = "--help" ]; then
    cat <<'USAGE'
Usage: update-standards.sh [--auto] [--answers FILE] [--dry-run] [--help]

Initialises docs/standards.md from the skill template when it does not
exist yet, or verifies it is present so the AI prompt can proceed with
filling/updating the placeholder tokens.

Exit codes:
  0  — file already exists (update mode) or was scaffolded (init mode)
  1  — aborted by user / missing template
USAGE
    exit 0
fi

read_context

SKILL_DIR="$(CDPATH="" cd "$SCRIPT_DIR/../.." && pwd)"
DOCS_DIR="$KISS_REPO_ROOT/$KISS_DOCS_DIR"
STANDARDS_FILE="$DOCS_DIR/standards.md"
TEMPLATE="$SKILL_DIR/templates/standard-template.md"
DEBTS_FILE="$DOCS_DIR/pm-debts.md"

TODAY=$(date +%Y-%m-%d)
PROJECT_NAME=$(resolve_auto STANDARDS_PROJECT_NAME "") || true

if [ "${KISS_DRY_RUN:-0}" = "1" ]; then
    if [ -f "$STANDARDS_FILE" ]; then
        echo "[dry-run] standards.md exists — would update: $STANDARDS_FILE"
    else
        echo "[dry-run] standards.md not found — would scaffold from template: $STANDARDS_FILE"
        echo "[dry-run] template: $TEMPLATE"
    fi
    echo "[dry-run] project_name: ${PROJECT_NAME:-<derived at AI-prompt time>}"
    exit 0
fi

if [ ! -f "$TEMPLATE" ]; then
    echo "Template not found: $TEMPLATE" >&2
    exit 1
fi

if [ -f "$STANDARDS_FILE" ]; then
    # File already exists — the AI prompt will perform the update in-place.
    echo "standards.md already exists: $STANDARDS_FILE"
    echo "MODE=update"
    exit 0
fi

# --- First-time initialisation ---
if ! confirm_before_write "Scaffold standards.md at $STANDARDS_FILE from template."; then
    echo "Aborted." >&2
    exit 1
fi

mkdir -p "$DOCS_DIR"

# Resolve project name: try STANDARDS_PROJECT_NAME env, then git remote,
# then fallback to the basename of the repo root.
if [ -z "$PROJECT_NAME" ]; then
    if git -C "$KISS_REPO_ROOT" remote get-url origin >/dev/null 2>&1; then
        PROJECT_NAME=$(git -C "$KISS_REPO_ROOT" remote get-url origin 2>/dev/null \
            | sed 's|.*[/:]||;s|\.git$||' || true)
    fi
fi
: "${PROJECT_NAME:=$(basename "$KISS_REPO_ROOT")}"

sed \
    -e "s|\[PROJECT_NAME\]|$PROJECT_NAME|g" \
    -e "s|\[RATIFICATION_DATE\]|$TODAY|g" \
    -e "s|\[LAST_AMENDED_DATE\]|$TODAY|g" \
    -e "s|\[STANDARDS_VERSION\]|1.0.0|g" \
    "$TEMPLATE" > "$STANDARDS_FILE"

write_extract "$STANDARDS_FILE" \
    "PROJECT_NAME=$PROJECT_NAME" \
    "STANDARDS_VERSION=1.0.0" \
    "RATIFICATION_DATE=$TODAY" \
    "LAST_AMENDED_DATE=$TODAY" > /dev/null

echo "Scaffolded $STANDARDS_FILE"
echo "MODE=init"

# Record a debt so the user knows they still need to fill placeholders.
append_debt "$DEBTS_FILE" PMDEBT \
    "standards.md was scaffolded on $TODAY with placeholder tokens — replace all [UPPER_CASE] tokens (Area: Standards, Priority: 🔴 Urgent)" > /dev/null
