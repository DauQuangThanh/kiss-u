#!/usr/bin/env bash
set -e
SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"
kiss_parse_standard_args "$@"
set -- "${KISS_REST_ARGS[@]}"

if [ "${1:-}" = "--help" ]; then
    cat <<'USAGE'
Usage: create-baseline.sh [--auto] [--answers FILE] [--dry-run] [--help]

Snapshots artefacts as a named baseline under docs/baselines/<label>/.

Answer keys: BASELINE_TYPE, BASELINE_LABEL, BASELINE_GIT_TAG_AUTO,
             BASELINE_EXTRA_FILES.
Valid types: requirements | design | test | release | custom
USAGE
    exit 0
fi

read_context

SKILL_DIR="$(CDPATH="" cd "$SCRIPT_DIR/../.." && pwd)"
DATE=$(date +%Y-%m-%d)

BTYPE=$(resolve_auto BASELINE_TYPE "") || true
if [ -z "$BTYPE" ]; then
    echo "ERROR: BASELINE_TYPE is required. Valid: requirements | design | test | release | custom" >&2
    exit 2
fi
case "$BTYPE" in requirements|design|test|release|custom) ;; *)
    echo "ERROR: Unknown BASELINE_TYPE '$BTYPE'." >&2; exit 2 ;;
esac

LABEL=$(resolve_auto BASELINE_LABEL "${BTYPE}-v${DATE}") || true
GIT_TAG_AUTO=$(resolve_auto BASELINE_GIT_TAG_AUTO "false") || true
EXTRA_FILES=$(resolve_auto BASELINE_EXTRA_FILES "") || true

BASELINE_DIR="$KISS_REPO_ROOT/$KISS_DOCS_DIR/baselines/$LABEL"
ARTEFACTS_DIR="$BASELINE_DIR/artefacts"
MANIFEST_OUT="$BASELINE_DIR/manifest.md"
DEBTS="$BASELINE_DIR/baseline-debts.md"

if [ "${KISS_DRY_RUN:-0}" = "1" ]; then
    echo "[dry-run] would create baseline: $BASELINE_DIR"
    echo "  type=$BTYPE  label=$LABEL  git_tag_auto=$GIT_TAG_AUTO"
    exit 0
fi

if [ -d "$BASELINE_DIR" ]; then
    echo "ERROR: Baseline '$LABEL' already exists at $BASELINE_DIR. Choose a different label." >&2
    exit 2
fi

if ! confirm_before_write "Create baseline '$LABEL' at $BASELINE_DIR."; then
    echo "Aborted." >&2
    exit 1
fi

mkdir -p "$ARTEFACTS_DIR"

# Determine file set by type
FILE_LIST=()
DOCS="$KISS_REPO_ROOT/$KISS_DOCS_DIR"
SPECS="$KISS_REPO_ROOT/$KISS_SPECS_DIR"
case "$BTYPE" in
    requirements)
        [ -f "$DOCS/analysis/srs.md" ] && FILE_LIST+=("$DOCS/analysis/srs.md")
        while IFS= read -r -d '' f; do FILE_LIST+=("$f"); done < <(find "$SPECS" -name "spec.md" -print0 2>/dev/null || true)
        ;;
    design)
        [ -f "$DOCS/analysis/srs.md" ] && FILE_LIST+=("$DOCS/analysis/srs.md")
        while IFS= read -r -d '' f; do FILE_LIST+=("$f"); done < <(find "$DOCS/design" -name "*.md" -print0 2>/dev/null || true)
        while IFS= read -r -d '' f; do FILE_LIST+=("$f"); done < <(find "$DOCS/decisions" -name "*.md" -print0 2>/dev/null || true)
        ;;
    test)
        while IFS= read -r -d '' f; do FILE_LIST+=("$f"); done < <(find "$DOCS/testing" -name "*.md" -print0 2>/dev/null || true)
        ;;
    release)
        while IFS= read -r -d '' f; do FILE_LIST+=("$f"); done < <(find "$DOCS/architecture" -name "*.md" -print0 2>/dev/null || true)
        while IFS= read -r -d '' f; do FILE_LIST+=("$f"); done < <(find "$DOCS/design" -name "*.md" -print0 2>/dev/null || true)
        while IFS= read -r -d '' f; do FILE_LIST+=("$f"); done < <(find "$DOCS/testing" -name "*.md" -print0 2>/dev/null || true)
        ;;
    custom)
        ;;
esac

# Add extra files
if [ -n "$EXTRA_FILES" ]; then
    IFS=':' read -ra EXTRAS <<< "$EXTRA_FILES"
    for f in "${EXTRAS[@]}"; do
        [ -f "$KISS_REPO_ROOT/$f" ] && FILE_LIST+=("$KISS_REPO_ROOT/$f")
    done
fi

FILE_COUNT="${#FILE_LIST[@]}"
GIT_BRANCH=$(git -C "$KISS_REPO_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
GIT_SHA=$(git -C "$KISS_REPO_ROOT" rev-parse HEAD 2>/dev/null || echo "unknown")

# Copy files and build manifest rows
ROWS=""
for src in "${FILE_LIST[@]}"; do
    if [ ! -f "$src" ]; then
        append_debt "$DEBTS" BASEDEBT "File not found: $src" > /dev/null
        continue
    fi
    rel="${src#$KISS_REPO_ROOT/}"
    dst="$ARTEFACTS_DIR/$rel"
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
    sha=$(shasum -a 256 "$src" 2>/dev/null | awk '{print $1}' || echo "n/a")
    sz=$(wc -c < "$src" | tr -d ' ')
    ROWS+="| $rel | artefacts/$rel | \`${sha:0:16}…\` | ${sz}B |"$'\n'
done

# Write manifest
cp "$SKILL_DIR/templates/manifest-template.md" "$MANIFEST_OUT"
sed -i.bak \
    -e "s|{label}|$LABEL|g" \
    -e "s|{type}|$BTYPE|g" \
    -e "s|{date}|$DATE|g" \
    -e "s|{file_count}|$FILE_COUNT|g" \
    -e "s|{git_branch}|$GIT_BRANCH|g" \
    -e "s|{git_sha}|${GIT_SHA:0:12}|g" \
    "$MANIFEST_OUT" && rm -f "$MANIFEST_OUT.bak"

# Append rows
printf '%s' "$ROWS" >> "$MANIFEST_OUT"

write_extract "$MANIFEST_OUT" \
    "BASELINE_LABEL=$LABEL" \
    "BASELINE_TYPE=$BTYPE" \
    "BASELINE_DATE=$DATE" \
    "GIT_TAG=baseline/$LABEL" \
    "GIT_SHA=$GIT_SHA" \
    "FILE_COUNT=$FILE_COUNT" > /dev/null

echo "Wrote baseline manifest: $MANIFEST_OUT"
echo "Files copied: $FILE_COUNT"

if [ "$GIT_TAG_AUTO" = "true" ]; then
    if git -C "$KISS_REPO_ROOT" tag -a "baseline/$LABEL" -m "Baseline $LABEL — $BTYPE phase" 2>/dev/null; then
        echo "Git tag created: baseline/$LABEL"
    else
        echo "WARNING: Could not create git tag. Run manually: git tag -a baseline/$LABEL -m 'Baseline $LABEL'" >&2
    fi
else
    echo ""
    echo "To tag this baseline in git, run:"
    echo "  git tag -a baseline/$LABEL -m \"Baseline $LABEL — $BTYPE phase\""
    echo "  git push origin baseline/$LABEL"
fi
