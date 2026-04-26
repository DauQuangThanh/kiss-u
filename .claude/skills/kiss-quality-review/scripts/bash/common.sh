#!/usr/bin/env bash
# Shared helpers for KISS role skills.
#
# Every role-skill's action scripts source this file to get:
#   - read_context            : parse .kiss/context.yml into KISS_* env vars
#   - worktype_dir <name>     : resolve docs/<work-type>/
#   - feature_scoped_dir <wt> : resolve docs/<work-type>/<feature>/
#   - append_debt <f> <p> <b> : append a numbered debt entry
#   - write_extract <path> …  : write a .extract companion file
#   - confirm_before_write …  : honour preferences.confirm_before_write
#   - resolve_auto <key>      : --auto / env / answers / .extract lookup
#
# Design notes:
#   * Fails softly. Missing .kiss/context.yml => warns once, applies
#     documented defaults (paths.docs=docs/, paths.specs=docs/specs/, …).
#   * YAML parsing: python3 with PyYAML → python3 without PyYAML
#     (minimal tokeniser) → grep fallback. We never REQUIRE python3
#     or yq, because kiss wheels install offline.
#   * All functions are idempotent; sourcing the file twice is safe.

# -------------------------------------------------------------------
# Repo root discovery (re-uses the existing kiss-specify convention).
# -------------------------------------------------------------------

find_kiss_root() {
    local dir="${1:-$(pwd)}"
    dir="$(cd -- "$dir" 2>/dev/null && pwd)" || return 1
    local prev_dir=""
    while true; do
        if [ -d "$dir/.kiss" ]; then
            echo "$dir"
            return 0
        fi
        if [ "$dir" = "/" ] || [ "$dir" = "$prev_dir" ]; then
            break
        fi
        prev_dir="$dir"
        dir="$(dirname "$dir")"
    done
    return 1
}

get_repo_root() {
    local kiss_root
    if kiss_root=$(find_kiss_root); then
        echo "$kiss_root"
        return
    fi
    if git rev-parse --show-toplevel >/dev/null 2>&1; then
        git rev-parse --show-toplevel
        return
    fi
    local script_dir
    script_dir="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    (cd "$script_dir/../../../.." && pwd)
}

# -------------------------------------------------------------------
# Context-file parsing.
# -------------------------------------------------------------------

# Documented defaults — match src/kiss_cli/context.py create_context_file().
_KISS_DEFAULT_DOCS_DIR="docs"
_KISS_DEFAULT_SPECS_DIR="docs/specs"
_KISS_DEFAULT_PLANS_DIR="docs/plans"
_KISS_DEFAULT_TASKS_DIR="docs/tasks"
_KISS_DEFAULT_TEMPLATES_DIR="templates"
_KISS_DEFAULT_SCRIPTS_DIR="scripts"

_kiss_context_warned=""

_kiss_warn_context_missing() {
    if [ -z "$_kiss_context_warned" ]; then
        echo "[kiss] .kiss/context.yml not found — applying documented defaults" >&2
        _kiss_context_warned=1
    fi
}

# Parse a .kiss/context.yml via python3 (+ PyYAML if available) and
# emit shell-safe KEY=VALUE lines. Stdout is designed for `eval`.
_kiss_parse_context_python() {
    local context_file="$1"
    command -v python3 >/dev/null 2>&1 || return 1
    python3 - "$context_file" <<'PY' 2>/dev/null
import os, sys
path = sys.argv[1]
try:
    import yaml  # type: ignore
    with open(path, "r") as f:
        data = yaml.safe_load(f) or {}
except ImportError:
    # Minimal fallback: hand-parse the 2-level-deep scalars we care
    # about. This matches the documented schema exactly.
    data = {"paths": {}, "current": {}, "preferences": {}}
    section = None
    with open(path, "r") as f:
        for raw in f:
            line = raw.rstrip("\n")
            if not line or line.lstrip().startswith("#"):
                continue
            if not line.startswith(" ") and line.endswith(":"):
                section = line[:-1]
                if section not in data:
                    data[section] = {}
                continue
            if line.startswith("  ") and ":" in line:
                key, _, value = line.strip().partition(":")
                value = value.strip()
                if value.startswith('"') and value.endswith('"'):
                    value = value[1:-1]
                elif value.startswith("'") and value.endswith("'"):
                    value = value[1:-1]
                if section and section in data:
                    data[section][key.strip()] = None if value in ("null", "~", "") else value
except Exception as e:
    print(f"KISS_CONTEXT_ERROR={e!s}")
    sys.exit(0)

def esc(v):
    if v is None:
        return ""
    s = str(v)
    # shell-safe quoting
    return "'" + s.replace("'", "'\\''") + "'"

paths = data.get("paths", {}) or {}
current = data.get("current", {}) or {}
prefs = data.get("preferences", {}) or {}

print(f"KISS_DOCS_DIR={esc(paths.get('docs'))}")
print(f"KISS_SPECS_DIR={esc(paths.get('specs'))}")
print(f"KISS_PLANS_DIR={esc(paths.get('plans'))}")
print(f"KISS_TASKS_DIR={esc(paths.get('tasks'))}")
print(f"KISS_TEMPLATES_DIR={esc(paths.get('templates'))}")
print(f"KISS_SCRIPTS_DIR={esc(paths.get('scripts'))}")
print(f"KISS_CURRENT_FEATURE={esc(current.get('feature'))}")
print(f"KISS_CURRENT_SPEC={esc(current.get('spec'))}")
print(f"KISS_CURRENT_PLAN={esc(current.get('plan'))}")
print(f"KISS_CURRENT_TASK={esc(current.get('task'))}")
print(f"KISS_CURRENT_CHECKLIST={esc(current.get('checklist'))}")
print(f"KISS_CURRENT_BRANCH={esc(current.get('branch'))}")
print(f"KISS_CONFIRM_BEFORE_WRITE={esc(prefs.get('confirm_before_write', True))}")
print(f"KISS_OUTPUT_FORMAT={esc(prefs.get('output_format', 'markdown'))}")
PY
}

# Pure-grep fallback — only extracts the minimum we need when python3
# is unavailable. Matches `  key: value` under known section headers.
_kiss_parse_context_grep() {
    local context_file="$1"
    local section=""
    while IFS= read -r raw; do
        # strip trailing newline + comments
        local line="${raw%$'\r'}"
        case "$line" in
            "#"*|"") continue ;;
        esac
        if [[ "$line" =~ ^([a-z_]+):[[:space:]]*$ ]]; then
            section="${BASH_REMATCH[1]}"
            continue
        fi
        if [[ "$line" =~ ^[[:space:]]+([a-z_]+):[[:space:]]*(.*)$ ]]; then
            local key="${BASH_REMATCH[1]}"
            local value="${BASH_REMATCH[2]}"
            # strip enclosing quotes
            value="${value%\"}"
            value="${value#\"}"
            value="${value%\'}"
            value="${value#\'}"
            # null markers
            case "$value" in
                "null"|"~"|"") value="" ;;
            esac
            case "$section/$key" in
                paths/docs)      printf "KISS_DOCS_DIR=%q\n" "$value" ;;
                paths/specs)     printf "KISS_SPECS_DIR=%q\n" "$value" ;;
                paths/plans)     printf "KISS_PLANS_DIR=%q\n" "$value" ;;
                paths/tasks)     printf "KISS_TASKS_DIR=%q\n" "$value" ;;
                paths/templates) printf "KISS_TEMPLATES_DIR=%q\n" "$value" ;;
                paths/scripts)   printf "KISS_SCRIPTS_DIR=%q\n" "$value" ;;
                current/feature)   printf "KISS_CURRENT_FEATURE=%q\n" "$value" ;;
                current/spec)      printf "KISS_CURRENT_SPEC=%q\n" "$value" ;;
                current/plan)      printf "KISS_CURRENT_PLAN=%q\n" "$value" ;;
                current/task)      printf "KISS_CURRENT_TASK=%q\n" "$value" ;;
                current/checklist) printf "KISS_CURRENT_CHECKLIST=%q\n" "$value" ;;
                current/branch)    printf "KISS_CURRENT_BRANCH=%q\n" "$value" ;;
                preferences/confirm_before_write) printf "KISS_CONFIRM_BEFORE_WRITE=%q\n" "$value" ;;
                preferences/output_format)        printf "KISS_OUTPUT_FORMAT=%q\n" "$value" ;;
            esac
        fi
    done < "$context_file"
}

# Populate KISS_* env vars from .kiss/context.yml (or defaults).
# Idempotent: subsequent calls re-read the file.
read_context() {
    local repo_root
    repo_root=$(get_repo_root)
    local context_file="$repo_root/.kiss/context.yml"

    # Start with defaults so downstream code never sees empty vars.
    export KISS_REPO_ROOT="$repo_root"
    export KISS_DOCS_DIR="$_KISS_DEFAULT_DOCS_DIR"
    export KISS_SPECS_DIR="$_KISS_DEFAULT_SPECS_DIR"
    export KISS_PLANS_DIR="$_KISS_DEFAULT_PLANS_DIR"
    export KISS_TASKS_DIR="$_KISS_DEFAULT_TASKS_DIR"
    export KISS_TEMPLATES_DIR="$_KISS_DEFAULT_TEMPLATES_DIR"
    export KISS_SCRIPTS_DIR="$_KISS_DEFAULT_SCRIPTS_DIR"
    export KISS_CURRENT_FEATURE=""
    export KISS_CURRENT_SPEC=""
    export KISS_CURRENT_PLAN=""
    export KISS_CURRENT_TASK=""
    export KISS_CURRENT_CHECKLIST=""
    export KISS_CURRENT_BRANCH=""
    export KISS_CONFIRM_BEFORE_WRITE="true"
    export KISS_OUTPUT_FORMAT="markdown"

    if [ ! -f "$context_file" ]; then
        _kiss_warn_context_missing
        return 0
    fi

    local parsed
    if parsed=$(_kiss_parse_context_python "$context_file" 2>/dev/null) && [ -n "$parsed" ]; then
        eval "$parsed"
    else
        parsed=$(_kiss_parse_context_grep "$context_file")
        if [ -n "$parsed" ]; then
            eval "$parsed"
        fi
    fi

    # Re-apply defaults where the context file left a slot null/empty.
    # Using ${VAR:=default} so we never leak a non-zero exit under set -e.
    : "${KISS_DOCS_DIR:=$_KISS_DEFAULT_DOCS_DIR}"
    : "${KISS_SPECS_DIR:=$_KISS_DEFAULT_SPECS_DIR}"
    : "${KISS_PLANS_DIR:=$_KISS_DEFAULT_PLANS_DIR}"
    : "${KISS_TASKS_DIR:=$_KISS_DEFAULT_TASKS_DIR}"
    : "${KISS_TEMPLATES_DIR:=$_KISS_DEFAULT_TEMPLATES_DIR}"
    : "${KISS_SCRIPTS_DIR:=$_KISS_DEFAULT_SCRIPTS_DIR}"
    : "${KISS_CONFIRM_BEFORE_WRITE:=true}"
    : "${KISS_OUTPUT_FORMAT:=markdown}"

    # Normalise Python/YAML boolean representations to lower-case.
    case "$KISS_CONFIRM_BEFORE_WRITE" in
        True|TRUE)   KISS_CONFIRM_BEFORE_WRITE="true" ;;
        False|FALSE) KISS_CONFIRM_BEFORE_WRITE="false" ;;
    esac

    # Agent mode (auto | interactive). When `auto`, we also enable
    # KISS_AUTO so skill action scripts take non-interactive paths.
    : "${KISS_AGENT_MODE:=interactive}"
    case "$KISS_AGENT_MODE" in
        auto|AUTO|Auto)
            KISS_AGENT_MODE="auto"
            : "${KISS_AUTO:=1}"
            ;;
        *)
            KISS_AGENT_MODE="interactive"
            ;;
    esac
    export KISS_AGENT_MODE
}

# -------------------------------------------------------------------
# Path resolution for work-type directories.
# -------------------------------------------------------------------

# Return (and create) $KISS_DOCS_DIR/<work-type>/ under the repo root.
worktype_dir() {
    local name="$1"
    if [ -z "$name" ]; then
        echo "worktype_dir: work-type name required" >&2
        return 1
    fi
    : "${KISS_REPO_ROOT:?read_context must be called first}"
    local dir="$KISS_REPO_ROOT/$KISS_DOCS_DIR/$name"
    mkdir -p "$dir"
    echo "$dir"
}

# Return (and create) $KISS_DOCS_DIR/<work-type>/<feature>/. Errors if
# current.feature is null.
feature_scoped_dir() {
    local name="$1"
    if [ -z "$name" ]; then
        echo "feature_scoped_dir: work-type name required" >&2
        return 1
    fi
    if [ -z "$KISS_CURRENT_FEATURE" ]; then
        echo "feature_scoped_dir: .kiss/context.yml 'current.feature' is not set" >&2
        return 1
    fi
    : "${KISS_REPO_ROOT:?read_context must be called first}"
    local dir="$KISS_REPO_ROOT/$KISS_DOCS_DIR/$name/$KISS_CURRENT_FEATURE"
    mkdir -p "$dir"
    echo "$dir"
}

# -------------------------------------------------------------------
# Agent-decisions log.
#
# Records assumptions + non-trivial decisions the agent made, so the
# user can audit what happened (especially in auto mode). Debts and
# decisions are separate: a debt is an UNresolved item the user still
# needs to answer; a decision is a resolved choice the AI already
# made on the user's behalf.
#
# File layout: docs/agent-decisions/<agent>/<YYYY-MM-DD>-decisions.md
# Agent name is taken from KISS_AGENT (set by the calling agent);
# defaults to "shared" when a skill is invoked standalone.
#
# Decision kinds:
#   - default-applied     — required input missing → default used
#   - alternative-picked  — chose one of >=2 viable options without asking
#   - autonomous-action   — wrote an artefact the user didn't explicitly request
#   - debt-overridden     — proceeded past a flagged debt on user's say-so
#
#   write_decision <kind> <what> [<why>] [<alternatives>]
#
# Emits the generated decision id (e.g. "D-03") on stdout.
# -------------------------------------------------------------------

write_decision() {
    local kind="$1"
    local what="$2"
    local why="${3:-}"
    local alts="${4:-}"
    if [ -z "$kind" ] || [ -z "$what" ]; then
        echo "write_decision: <kind> <what> required" >&2
        return 1
    fi
    case "$kind" in
        default-applied|alternative-picked|autonomous-action|debt-overridden) ;;
        *)
            echo "write_decision: unknown kind '$kind' (must be one of default-applied|alternative-picked|autonomous-action|debt-overridden)" >&2
            return 1
            ;;
    esac

    : "${KISS_REPO_ROOT:?read_context must be called first}"
    local agent="${KISS_AGENT:-shared}"
    local date_s
    date_s=$(date +%Y-%m-%d)
    local dir="$KISS_REPO_ROOT/$KISS_DOCS_DIR/agent-decisions/$agent"
    local file="$dir/$date_s-decisions.md"
    mkdir -p "$dir"

    local next=1
    if [ -f "$file" ]; then
        local last
        last=$(grep -Eo '^### D-[0-9]+' "$file" 2>/dev/null | grep -Eo '[0-9]+' | sort -n | tail -n1 || true)
        [ -n "$last" ] && next=$((10#$last + 1))
    else
        {
            printf '# Agent decisions — %s — %s\n\n' "$agent" "$date_s"
            printf '**Mode:** %s\n\n' "${KISS_AGENT_MODE:-interactive}"
        } > "$file"
    fi

    local id
    id=$(printf 'D-%02d' "$next")
    local iso_time
    iso_time=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    {
        printf '### %s — %s\n\n' "$id" "$kind"
        printf -- '- **What:** %s\n' "$what"
        [ -n "$why" ]  && printf -- '- **Why:** %s\n' "$why"
        [ -n "$alts" ] && printf -- '- **Alternatives considered:** %s\n' "$alts"
        printf -- '- **Time:** %s\n\n' "$iso_time"
    } >> "$file"
    echo "$id"
}

# -------------------------------------------------------------------
# Debt register.
# -------------------------------------------------------------------

# Append a numbered debt entry. Auto-increments the suffix based on
# the existing entries in the file.
#   append_debt <file> <prefix> <body-line>
append_debt() {
    local file="$1"
    local prefix="$2"
    local body="$3"
    if [ -z "$file" ] || [ -z "$prefix" ] || [ -z "$body" ]; then
        echo "append_debt: <file> <prefix> <body> required" >&2
        return 1
    fi

    mkdir -p "$(dirname "$file")"

    local next=1
    if [ -f "$file" ]; then
        local last
        last=$(grep -Eo "^${prefix}-[0-9]+" "$file" 2>/dev/null | grep -Eo '[0-9]+$' | sort -n | tail -n1)
        if [ -n "$last" ]; then
            next=$((10#$last + 1))
        fi
    else
        printf '# Debt register (%s)\n\n' "$prefix" > "$file"
    fi

    printf '%s-%02d: %s\n' "$prefix" "$next" "$body" >> "$file"
    printf '%s-%02d\n' "$prefix" "$next"
}

# -------------------------------------------------------------------
# .extract companion files.
# -------------------------------------------------------------------

# Write a flat KEY=VALUE ledger next to an output artefact so the next
# skill in the chain does not have to re-parse markdown.
#   write_extract <artefact-path> KEY=VAL [KEY=VAL …]
write_extract() {
    local artefact="$1"
    shift || true
    if [ -z "$artefact" ]; then
        echo "write_extract: artefact path required" >&2
        return 1
    fi
    local extract="${artefact%.*}.extract"
    mkdir -p "$(dirname "$extract")"
    : > "$extract"
    local pair key value
    for pair in "$@"; do
        key="${pair%%=*}"
        value="${pair#*=}"
        printf '%s=%s\n' "$key" "$value" >> "$extract"
    done
    echo "$extract"
}

# -------------------------------------------------------------------
# confirm_before_write
# -------------------------------------------------------------------

# Prompt the user interactively unless preferences.confirm_before_write
# is false OR --auto was passed. Returns 0 to proceed, 1 to abort.
confirm_before_write() {
    local message="${1:-About to write.}"
    if [ "${KISS_AUTO:-0}" = "1" ]; then
        return 0
    fi
    if [ "${KISS_CONFIRM_BEFORE_WRITE:-true}" != "true" ]; then
        return 0
    fi
    printf '%s  Proceed? [y/N] ' "$message" >&2
    local answer
    IFS= read -r answer || answer=""
    case "$answer" in
        [yY]|[yY][eE][sS]) return 0 ;;
        *) return 1 ;;
    esac
}

# -------------------------------------------------------------------
# --auto / env / answers / .extract resolution chain.
# -------------------------------------------------------------------

# Load KEY=VALUE lines from an answers file into the current env, but
# only if the variable is not already set (env > answers).
kiss_load_answers() {
    local file="$1"
    [ -f "$file" ] || return 0
    local line key value
    while IFS= read -r line || [ -n "$line" ]; do
        case "$line" in
            "#"*|"") continue ;;
        esac
        key="${line%%=*}"
        value="${line#*=}"
        # strip surrounding quotes
        value="${value%\"}"
        value="${value#\"}"
        # only set if missing
        if [ -z "${!key:-}" ]; then
            export "$key=$value"
        fi
    done < "$file"
}

# Resolve an answer key in the documented priority order:
#   1. the named env var already set in-process
#   2. KISS_ANSWERS file (loaded by the action script)
#   3. an upstream .extract file (each path passed via KISS_EXTRACTS,
#      colon-separated)
#   4. the caller-supplied default
# Prints the resolved value and returns 0 if resolved, 1 if the
# default was used. Callers running under `set -e` should use
# `val=$(resolve_auto KEY DEFAULT) || true`.
resolve_auto() {
    local key="$1"
    local default="${2:-}"

    # 1. in-process env
    if [ -n "${!key:-}" ]; then
        printf '%s' "${!key}"
        return 0
    fi

    # 2. answers file (if set but not yet loaded — usually loaded once
    # per action, but we guard here for safety)
    if [ -n "${KISS_ANSWERS:-}" ] && [ -f "$KISS_ANSWERS" ]; then
        local val
        val=$(grep -E "^${key}=" "$KISS_ANSWERS" 2>/dev/null | head -n1 | cut -d= -f2- || true)
        if [ -n "$val" ]; then
            printf '%s' "$val"
            return 0
        fi
    fi

    # 3. .extract chain
    if [ -n "${KISS_EXTRACTS:-}" ]; then
        local IFS=':'
        local extract
        for extract in $KISS_EXTRACTS; do
            [ -f "$extract" ] || continue
            local val
            val=$(grep -E "^${key}=" "$extract" 2>/dev/null | head -n1 | cut -d= -f2- || true)
            if [ -n "$val" ]; then
                printf '%s' "$val"
                return 0
            fi
        done
    fi

    # 4. default — return non-zero so callers can log a debt if the
    # default kicked in.
    printf '%s' "$default"
    return 1
}

# Standard argument parser for action scripts. Consumes --auto,
# --answers FILE, --dry-run, --help; leaves positional args in the
# caller's "$@".
#   Usage at the top of an action script:
#     source "$(dirname "$0")/common.sh"
#     kiss_parse_standard_args "$@"; set -- "${KISS_REST_ARGS[@]}"
KISS_REST_ARGS=()
kiss_parse_standard_args() {
    KISS_REST_ARGS=()
    export KISS_AUTO="${KISS_AUTO:-0}"
    export KISS_DRY_RUN="${KISS_DRY_RUN:-0}"
    export KISS_ANSWERS="${KISS_ANSWERS:-}"
    while [ $# -gt 0 ]; do
        case "$1" in
            --auto)    KISS_AUTO=1 ;;
            --dry-run) KISS_DRY_RUN=1 ;;
            --answers)
                if [ $# -lt 2 ]; then
                    echo "--answers requires a file path" >&2
                    return 1
                fi
                KISS_ANSWERS="$2"
                shift
                ;;
            --help|-h)
                KISS_REST_ARGS+=("--help")
                ;;
            *)
                KISS_REST_ARGS+=("$1")
                ;;
        esac
        shift
    done
    if [ -n "$KISS_ANSWERS" ]; then
        kiss_load_answers "$KISS_ANSWERS"
    fi
    export KISS_AUTO KISS_DRY_RUN KISS_ANSWERS
}
