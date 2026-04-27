#!/usr/bin/env bash
# Scaffold a Vue 3 SPA mockup (Vite + TypeScript + Tailwind CSS v4 +
# PrimeVue + Vue Router v4 + Pinia) into a target directory.
#
# Usage:
#   scaffold-vue-spa.sh [--auto] [--answers FILE] [--dry-run] [--help]
#
# Answer keys (resolved in env > --answers file > .extract > default order):
#   KISS_VUE_SPA_OUTPUT_DIR  — directory to scaffold into              (default: mockup)
#   KISS_VUE_SPA_APP_NAME    — npm package name                        (default: feature slug or my-app)
#   KISS_VUE_SPA_VIEWS       — comma-separated view names              (default: Home)
#   KISS_VUE_SPA_THEME       — initial theme: system | light | dark    (default: system)
#   KISS_VUE_SPA_LOCALES     — comma-separated BCP-47 locale codes     (default: en,vi)

set -e

SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

kiss_parse_standard_args "$@"
set -- "${KISS_REST_ARGS[@]}"

if [ "${1:-}" = "--help" ]; then
    cat <<'USAGE'
Usage: scaffold-vue-spa.sh [--auto] [--answers FILE] [--dry-run] [--help]

Scaffolds a Vue 3 SPA mockup (Vite + TypeScript + Tailwind CSS v4 +
PrimeVue + Vue Router v4 + Pinia).

Flags:
  --auto            Non-interactive; resolve answers from env/answers/extracts/defaults
  --answers FILE    KEY=VALUE file consulted when --auto
  --dry-run         Print what would be written, do not touch the filesystem
  --help            Show this message and exit

Answer keys:
  KISS_VUE_SPA_OUTPUT_DIR   Output directory                        (default: mockup)
  KISS_VUE_SPA_APP_NAME     npm package name                        (default: feature slug or my-app)
  KISS_VUE_SPA_VIEWS        Comma-separated view names              (default: Home)
  KISS_VUE_SPA_THEME        Initial theme: system | light | dark    (default: system)
  KISS_VUE_SPA_LOCALES      Comma-separated BCP-47 locale codes     (default: en,vi)
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

OUTPUT_DIR=$(resolve_auto KISS_VUE_SPA_OUTPUT_DIR "mockup")                  || \
    write_decision default-applied "KISS_VUE_SPA_OUTPUT_DIR=mockup" \
        "No output directory specified" > /dev/null
APP_NAME=$(resolve_auto KISS_VUE_SPA_APP_NAME "$_DEFAULT_APP_NAME")          || \
    write_decision default-applied "KISS_VUE_SPA_APP_NAME=$_DEFAULT_APP_NAME" \
        "No app name specified" > /dev/null
VIEWS_RAW=$(resolve_auto KISS_VUE_SPA_VIEWS "Home")                          || \
    write_decision default-applied "KISS_VUE_SPA_VIEWS=Home" \
        "No views specified" > /dev/null
THEME=$(resolve_auto KISS_VUE_SPA_THEME "system")                            || \
    write_decision default-applied "KISS_VUE_SPA_THEME=system" \
        "No theme preference specified" > /dev/null
LOCALES_RAW=$(resolve_auto KISS_VUE_SPA_LOCALES "en,vi")                     || \
    write_decision default-applied "KISS_VUE_SPA_LOCALES=en,vi" \
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

OUT_ROOT="$KISS_REPO_ROOT/$OUTPUT_DIR"

# Split VIEWS_RAW on commas and trim whitespace
IFS=',' read -r -a VIEWS <<< "$VIEWS_RAW"
TRIMMED_VIEWS=()
for v in "${VIEWS[@]}"; do
    v="${v#"${v%%[![:space:]]*}"}"
    v="${v%"${v##*[![:space:]]}"}"
    [ -n "$v" ] && TRIMMED_VIEWS+=("$v")
done
VIEWS=("${TRIMMED_VIEWS[@]}")

DATE_NOW=$(date +%Y-%m-%d)

# ---------------------------------------------------------------------------
# Dry-run output
# ---------------------------------------------------------------------------

if [ "${KISS_DRY_RUN:-0}" = "1" ]; then
    echo "[dry-run] output directory:  $OUT_ROOT"
    echo "[dry-run] app name:          $APP_NAME"
    echo "[dry-run] views:             ${VIEWS[*]}"
    echo "[dry-run] theme:             $THEME"
    echo "[dry-run] locales:           ${LOCALES[*]}"
    echo "[dry-run] files that would be written:"
    for f in .gitignore index.html package.json tsconfig.json tsconfig.app.json \
              tsconfig.node.json vite.config.ts src/assets/main.css src/main.ts \
              src/App.vue src/router/index.ts src/stores/app.ts \
              src/i18n/index.ts; do
        echo "  $OUT_ROOT/$f"
    done
    for locale in "${LOCALES[@]}"; do
        echo "  $OUT_ROOT/src/locales/${locale}.json"
    done
    for view in "${VIEWS[@]}"; do
        echo "  $OUT_ROOT/src/views/${view}View.vue"
    done
    exit 0
fi

# ---------------------------------------------------------------------------
# Confirm before write
# ---------------------------------------------------------------------------

if ! confirm_before_write "Scaffold Vue 3 SPA mockup into $OUT_ROOT."; then
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
# Build router + App content based on view list
# ---------------------------------------------------------------------------

# Import lines for router/index.ts
ROUTER_IMPORTS=""
ROUTER_ROUTES=""
for view in "${VIEWS[@]}"; do
    view_lower=$(printf '%s' "$view" | tr '[:upper:]' '[:lower:]')
    ROUTER_IMPORTS="${ROUTER_IMPORTS}import ${view}View from '@/views/${view}View.vue'"$'\n'
    if [ "$view" = "Home" ]; then
        ROUTER_ROUTES="${ROUTER_ROUTES}  { path: '/', name: 'home', component: HomeView },"$'\n'
    else
        ROUTER_ROUTES="${ROUTER_ROUTES}  { path: '/${view_lower}', name: '${view_lower}', component: ${view}View },"$'\n'
    fi
done

# Nav links for App.vue
APP_NAV_LINKS=""
if [ "${#VIEWS[@]}" -gt 1 ]; then
    for view in "${VIEWS[@]}"; do
        view_lower=$(printf '%s' "$view" | tr '[:upper:]' '[:lower:]')
        route_name=$([ "$view" = "Home" ] && echo "home" || echo "$view_lower")
        APP_NAV_LINKS="${APP_NAV_LINKS}        <RouterLink :to=\"{ name: '${route_name}' }\" active-class=\"font-semibold text-primary\" class=\"text-muted-foreground hover:text-foreground transition-colors\">${view}</RouterLink>"$'\n'
    done
fi

# ---------------------------------------------------------------------------
# Scaffold directory structure and write files
# ---------------------------------------------------------------------------

echo "Scaffolding $OUT_ROOT ..."
mkdir -p "$OUT_ROOT/src/assets" "$OUT_ROOT/src/i18n" "$OUT_ROOT/src/locales" \
         "$OUT_ROOT/src/views" "$OUT_ROOT/src/router" "$OUT_ROOT/src/stores"

# Static files from templates
_write "$OUT_ROOT/.gitignore"           "$(_tpl gitignore.tpl)"
_write "$OUT_ROOT/index.html"           "$(_tpl index.html.tpl)"
_write "$OUT_ROOT/package.json"         "$(_tpl package.json.tpl)"
_write "$OUT_ROOT/tsconfig.json"        "$(_tpl tsconfig.json.tpl)"
_write "$OUT_ROOT/tsconfig.app.json"    "$(_tpl tsconfig.app.json.tpl)"
_write "$OUT_ROOT/tsconfig.node.json"   "$(_tpl tsconfig.node.json.tpl)"
_write "$OUT_ROOT/vite.config.ts"       "$(_tpl vite.config.ts.tpl)"
_write "$OUT_ROOT/src/assets/main.css"  "$(_tpl src-main.css.tpl)"
_write "$OUT_ROOT/src/main.ts"          "$(_tpl src-main.ts.tpl)"
_write "$OUT_ROOT/src/stores/app.ts"    "$(_tpl src-stores-app.ts.tpl)"
_write "$OUT_ROOT/src/i18n/index.ts"    "$(_tpl src-i18n-index.ts.tpl)"

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

# App.vue — inject nav links
APP_CONTENT=$(_tpl src-App.vue.tpl | sed "s|{nav_links}|${APP_NAV_LINKS}|g")
_write "$OUT_ROOT/src/App.vue" "$APP_CONTENT"

# router/index.ts — inject imports + routes
ROUTER_CONTENT=$(_tpl src-router-index.ts.tpl | \
    sed "s|{router_imports}|${ROUTER_IMPORTS}|g" | \
    sed "s|{router_routes}|${ROUTER_ROUTES}|g")
_write "$OUT_ROOT/src/router/index.ts" "$ROUTER_CONTENT"

# View files
VIEW_TPL=$(_tpl src-views-View.vue.tpl)
for view in "${VIEWS[@]}"; do
    VIEW_CONTENT=$(printf '%s' "$VIEW_TPL" | sed "s|{view_name}|${view}|g")
    _write "$OUT_ROOT/src/views/${view}View.vue" "$VIEW_CONTENT"
done

# ---------------------------------------------------------------------------
# Write .extract and debt entries
# ---------------------------------------------------------------------------

EXTRACT_FILE="$OUT_ROOT/vue-spa-mockup.extract"
write_extract "$EXTRACT_FILE" \
    "KISS_VUE_SPA_OUTPUT_DIR=$OUTPUT_DIR" \
    "KISS_VUE_SPA_APP_NAME=$APP_NAME" \
    "KISS_VUE_SPA_VIEWS=$VIEWS_RAW" \
    "KISS_VUE_SPA_THEME=$THEME" \
    "KISS_VUE_SPA_LOCALES=$LOCALES_RAW" > /dev/null

DEBTS_FILE="$KISS_REPO_ROOT/$KISS_DOCS_DIR/design/vue-spa-debts.md"
for view in "${VIEWS[@]}"; do
    append_debt "$DEBTS_FILE" VUEDEV \
        "View ${view}View only has placeholder content — replace with real UI" > /dev/null
done

echo ""
echo "Done. Next steps:"
echo "  cd $OUTPUT_DIR"
echo "  npm install"
echo "  npm run dev"
