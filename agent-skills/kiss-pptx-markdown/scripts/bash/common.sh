#!/usr/bin/env bash
# Shared helpers for kiss-pptx-markdown action scripts.
#
# These skills are standalone Office round-trip tools: they don't read
# .kiss/context.yml, don't write under docs/<work-type>/, and don't
# need the full kiss helper surface area. Sourcing this file gives
# the action scripts a tiny, consistent set of log helpers and the
# location of the bundle's Python scripts so setup_env / wrappers
# can resolve requirements.txt and venv_bootstrap.py reliably.

KISS_SKILL_SCRIPTS_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )/.." &> /dev/null && pwd )"
KISS_SKILL_NAME="kiss-pptx-markdown"

kiss_log()  { echo "[${KISS_SKILL_NAME}] $*"; }
kiss_warn() { echo "[${KISS_SKILL_NAME}] warning: $*" >&2; }
kiss_err()  { echo "[${KISS_SKILL_NAME}] error: $*"   >&2; }
