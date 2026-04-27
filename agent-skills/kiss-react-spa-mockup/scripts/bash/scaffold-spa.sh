#!/usr/bin/env bash
# Scaffold a React SPA mockup (Vite + TypeScript + Tailwind CSS v4 +
# shadcn/ui + React Router v7) into a target directory.
#
# Usage:
#   scaffold-spa.sh [--auto] [--answers FILE] [--dry-run] [--help]
#
# Answer keys (resolved in env > --answers file > .extract > default order):
#   KISS_SPA_OUTPUT_DIR  — directory to scaffold into              (default: mockup)
#   KISS_SPA_APP_NAME    — npm package name                        (default: feature slug or my-app)
#   KISS_SPA_PAGES       — comma-separated page names              (default: Home)
#   KISS_SPA_THEME       — initial theme: system | light | dark    (default: system)
#   KISS_SPA_LOCALES     — comma-separated BCP-47 locale codes     (default: en,vi)

set -e

SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

kiss_parse_standard_args "$@"
set -- "${KISS_REST_ARGS[@]}"

if [ "${1:-}" = "--help" ]; then
    cat <<'USAGE'
Usage: scaffold-spa.sh [--auto] [--answers FILE] [--dry-run] [--help]

Scaffolds a React SPA mockup (Vite + TypeScript + Tailwind CSS v4 +
shadcn/ui + React Router v7).

Flags:
  --auto            Non-interactive; resolve answers from env/answers/extracts/defaults
  --answers FILE    KEY=VALUE file consulted when --auto
  --dry-run         Print what would be written, do not touch the filesystem
  --help            Show this message and exit

Answer keys:
  KISS_SPA_OUTPUT_DIR   Output directory                        (default: mockup)
  KISS_SPA_APP_NAME     npm package name                        (default: feature slug or my-app)
  KISS_SPA_PAGES        Comma-separated page names              (default: Home)
  KISS_SPA_THEME        Initial theme: system | light | dark    (default: system)
  KISS_SPA_LOCALES      Comma-separated BCP-47 locale codes     (default: en,vi)
USAGE
    exit 0
fi

read_context

SKILL_DIR="$(CDPATH="" cd "$SCRIPT_DIR/../.." && pwd)"

# ---------------------------------------------------------------------------
# Resolve answer keys
# ---------------------------------------------------------------------------

_DEFAULT_FEATURE_SLUG="${KISS_CURRENT_FEATURE:-my-app}"
_DEFAULT_APP_NAME=$(printf '%s' "$_DEFAULT_FEATURE_SLUG" | tr '[:upper:] _/' '[:lower:]--')

OUTPUT_DIR=$(resolve_auto KISS_SPA_OUTPUT_DIR "mockup")                  || \
    write_decision default-applied "KISS_SPA_OUTPUT_DIR=mockup" \
        "No output directory specified" > /dev/null
APP_NAME=$(resolve_auto KISS_SPA_APP_NAME "$_DEFAULT_APP_NAME")          || \
    write_decision default-applied "KISS_SPA_APP_NAME=$_DEFAULT_APP_NAME" \
        "No app name specified" > /dev/null
PAGES_RAW=$(resolve_auto KISS_SPA_PAGES "Home")                          || \
    write_decision default-applied "KISS_SPA_PAGES=Home" \
        "No pages specified" > /dev/null
THEME=$(resolve_auto KISS_SPA_THEME "system")                            || \
    write_decision default-applied "KISS_SPA_THEME=system" \
        "No theme preference specified" > /dev/null
LOCALES_RAW=$(resolve_auto KISS_SPA_LOCALES "en,vi")                     || \
    write_decision default-applied "KISS_SPA_LOCALES=en,vi" \
        "No locales specified" > /dev/null

# Normalise theme value
case "$THEME" in
    light|Light|LIGHT) THEME="light" ;;
    dark|Dark|DARK)    THEME="dark" ;;
    *)                 THEME="system" ;;
esac

# Build locale array
IFS=',' read -r -a LOCALES <<< "$LOCALES_RAW"
TRIMMED_LOCALES=()
for l in "${LOCALES[@]}"; do
    l="${l#"${l%%[![:space:]]*}"}"
    l="${l%"${l##*[![:space:]]}"}" 
    l=$(printf '%s' "$l" | tr '[:upper:]' '[:lower:]')
    [ -n "$l" ] && TRIMMED_LOCALES+=("$l")
done
LOCALES=("${TRIMMED_LOCALES[@]}")
# Ensure en and vi are always included
_has_locale() { for x in "${LOCALES[@]}"; do [ "$x" = "$1" ] && return 0; done; return 1; }
_has_locale en || LOCALES=("en" "${LOCALES[@]}")
_has_locale vi || LOCALES=("${LOCALES[@]}" "vi")

# Build absolute output path (resolve relative to repo root)
OUT_ROOT="$KISS_REPO_ROOT/$OUTPUT_DIR"

# Split PAGES_RAW on commas
IFS=',' read -r -a PAGES <<< "$PAGES_RAW"
# Trim whitespace from each page name
TRIMMED_PAGES=()
for p in "${PAGES[@]}"; do
    p="${p#"${p%%[![:space:]]*}"}"
    p="${p%"${p##*[![:space:]]}"}"
    [ -n "$p" ] && TRIMMED_PAGES+=("$p")
done
PAGES=("${TRIMMED_PAGES[@]}")

DATE_NOW=$(date +%Y-%m-%d)

# ---------------------------------------------------------------------------
# Dry-run output
# ---------------------------------------------------------------------------

if [ "${KISS_DRY_RUN:-0}" = "1" ]; then
    echo "[dry-run] output directory:  $OUT_ROOT"
    echo "[dry-run] app name:          $APP_NAME"
    echo "[dry-run] pages:             ${PAGES[*]}"
    echo "[dry-run] theme:             $THEME"
    echo "[dry-run] locales:           ${LOCALES[*]}"
    echo "[dry-run] files that would be written:"
    echo "  $OUT_ROOT/.gitignore"
    echo "  $OUT_ROOT/components.json"
    echo "  $OUT_ROOT/index.html"
    echo "  $OUT_ROOT/package.json"
    echo "  $OUT_ROOT/tsconfig.json"
    echo "  $OUT_ROOT/tsconfig.app.json"
    echo "  $OUT_ROOT/vite.config.ts"
    echo "  $OUT_ROOT/src/index.css"
    echo "  $OUT_ROOT/src/main.tsx"
    echo "  $OUT_ROOT/src/App.tsx"
    echo "  $OUT_ROOT/src/router.tsx"
    echo "  $OUT_ROOT/src/hooks/useTheme.ts"
    echo "  $OUT_ROOT/src/i18n/setup.ts"
    echo "  $OUT_ROOT/src/lib/utils.ts"
    for locale in "${LOCALES[@]}"; do
        echo "  $OUT_ROOT/src/locales/${locale}.json"
    done
    for page in "${PAGES[@]}"; do
        echo "  $OUT_ROOT/src/pages/${page}.tsx"
    done
    exit 0
fi

# ---------------------------------------------------------------------------
# Confirm before write
# ---------------------------------------------------------------------------

if ! confirm_before_write "Scaffold React SPA mockup into $OUT_ROOT."; then
    echo "Aborted." >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

_tpl() {
    local tpl="$SKILL_DIR/templates/$1"
    if [ ! -f "$tpl" ]; then
        echo "ERROR: template not found: $tpl" >&2
        exit 2
    fi
    sed \
        -e "s|{app_name}|$APP_NAME|g" \
        -e "s|{date}|$DATE_NOW|g" \
        -e "s|{output_dir}|$OUTPUT_DIR|g" \
        -e "s|{theme}|$THEME|g" \
        "$tpl"
}

_write() {
    local dest="$1"
    local content="$2"
    mkdir -p "$(dirname "$dest")"
    printf '%s\n' "$content" > "$dest"
    echo "  wrote $dest"
}

# ---------------------------------------------------------------------------
# Build router + app content based on page list
# ---------------------------------------------------------------------------

# Build import + route lines for router.tsx
ROUTER_IMPORTS=""
ROUTER_ROUTES=""
for page in "${PAGES[@]}"; do
    ROUTER_IMPORTS="${ROUTER_IMPORTS}import ${page} from './pages/${page}';"$'\n'
    ROUTER_ROUTES="${ROUTER_ROUTES}  { path: '$([ "$page" = "Home" ] && echo "/" || printf "/%s" "$(printf '%s' "$page" | tr '[:upper:]' '[:lower:]')")', element: <${page} /> },"$'\n'
done

# Build nav links for App.tsx (only if more than one page)
APP_NAV_LINKS=""
if [ "${#PAGES[@]}" -gt 1 ]; then
    for page in "${PAGES[@]}"; do
        local_path=$([ "$page" = "Home" ] && echo "/" || printf "/%s" "$(printf '%s' "$page" | tr '[:upper:]' '[:lower:]')")
        APP_NAV_LINKS="${APP_NAV_LINKS}          <NavLink to=\"${local_path}\" className={({ isActive }) => isActive ? 'font-semibold text-primary' : 'text-muted-foreground hover:text-foreground transition-colors'}>${page}</NavLink>"$'\n'
    done
fi

# ---------------------------------------------------------------------------
# Scaffold directory structure and write files
# ---------------------------------------------------------------------------

echo "Scaffolding $OUT_ROOT ..."
mkdir -p "$OUT_ROOT/src/hooks" "$OUT_ROOT/src/i18n" "$OUT_ROOT/src/lib" \
         "$OUT_ROOT/src/locales" "$OUT_ROOT/src/pages"

# Static files from templates
_write "$OUT_ROOT/.gitignore"      "$(_tpl gitignore.tpl)"
_write "$OUT_ROOT/components.json" "$(_tpl components.json.tpl)"
_write "$OUT_ROOT/index.html"      "$(_tpl index.html.tpl)"
_write "$OUT_ROOT/package.json"    "$(_tpl package.json.tpl)"
_write "$OUT_ROOT/tsconfig.json"   "$(_tpl tsconfig.json.tpl)"
_write "$OUT_ROOT/tsconfig.app.json" "$(_tpl tsconfig.app.json.tpl)"
_write "$OUT_ROOT/vite.config.ts"  "$(_tpl vite.config.ts.tpl)"
_write "$OUT_ROOT/src/index.css"   "$(_tpl src-index.css.tpl)"
_write "$OUT_ROOT/src/main.tsx"         "$(_tpl src-main.tsx.tpl)"
_write "$OUT_ROOT/src/hooks/useTheme.ts" "$(_tpl src-hooks-useTheme.ts.tpl)"
_write "$OUT_ROOT/src/i18n/setup.ts"    "$(_tpl src-i18n-setup.ts.tpl)"
_write "$OUT_ROOT/src/lib/utils.ts"     "$(_tpl src-lib-utils.ts.tpl)"

# Locale files
LOCALE_STUB_TPL=$(_tpl src-locales-locale.json.tpl)
for locale in "${LOCALES[@]}"; do
    if [ -f "$SKILL_DIR/templates/src-locales-${locale}.json.tpl" ]; then
        LOCALE_CONTENT=$(_tpl "src-locales-${locale}.json.tpl")
    else
        LOCALE_CONTENT=$(printf '%s' "$LOCALE_STUB_TPL" | sed "s|{locale}|${locale}|g")
    fi
    _write "$OUT_ROOT/src/locales/${locale}.json" "$LOCALE_CONTENT"
done

# App.tsx — inject nav links
APP_CONTENT=$(_tpl src-App.tsx.tpl | \
    sed "s|{nav_links}|${APP_NAV_LINKS}|g")
_write "$OUT_ROOT/src/App.tsx" "$APP_CONTENT"

# router.tsx — inject imports + routes
ROUTER_CONTENT=$(_tpl src-router.tsx.tpl | \
    sed "s|{router_imports}|${ROUTER_IMPORTS}|g" | \
    sed "s|{router_routes}|${ROUTER_ROUTES}|g")
_write "$OUT_ROOT/src/router.tsx" "$ROUTER_CONTENT"

# Page files
PAGE_TPL=$(_tpl src-pages-Page.tsx.tpl)
for page in "${PAGES[@]}"; do
    PAGE_CONTENT=$(printf '%s' "$PAGE_TPL" | sed "s|{page_name}|${page}|g")
    _write "$OUT_ROOT/src/pages/${page}.tsx" "$PAGE_CONTENT"
done

# ---------------------------------------------------------------------------
# Write .extract and debt entries
# ---------------------------------------------------------------------------

EXTRACT_FILE="$OUT_ROOT/spa-mockup.extract"
write_extract "$EXTRACT_FILE" \
    "KISS_SPA_OUTPUT_DIR=$OUTPUT_DIR" \
    "KISS_SPA_APP_NAME=$APP_NAME" \
    "KISS_SPA_PAGES=$PAGES_RAW" \
    "KISS_SPA_THEME=$THEME" \
    "KISS_SPA_LOCALES=$LOCALES_RAW" > /dev/null

DEBTS_FILE="$KISS_REPO_ROOT/$KISS_DOCS_DIR/design/spa-debts.md"
for page in "${PAGES[@]}"; do
    append_debt "$DEBTS_FILE" SPADEV \
        "Page ${page} only has placeholder content — replace with real UI" > /dev/null
done

echo ""
echo "Done. Next steps:"
echo "  cd $OUTPUT_DIR"
echo "  npm install"
echo "  npm run dev"
