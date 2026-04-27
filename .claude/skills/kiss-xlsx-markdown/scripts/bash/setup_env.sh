#!/usr/bin/env bash
# Bootstrap a project-local virtualenv for kiss-xlsx-markdown.
#
# Creates ./.venv in the *current working directory* (so it sits next to your
# .xlsx files, not inside the skill folder), then pip-installs the skill's
# Python deps from scripts/requirements.txt.
#
# Run from the workspace where you want the venv to live:
#
#   bash <skill-dir>/scripts/bash/setup_env.sh
#
# Override the Python executable with: PYTHON=python3.12 bash setup_env.sh
#
# Note: LibreOffice (soffice) is an optional system dependency, only needed
# for --recalc / formula evaluation. Install via your package manager.
set -euo pipefail

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

REQS_FILE="${KISS_SKILL_SCRIPTS_DIR}/requirements.txt"
VENV_DIR="${VENV_DIR:-.venv}"
PYTHON_BIN="${PYTHON:-python3}"

if ! command -v "${PYTHON_BIN}" > /dev/null 2>&1; then
    kiss_err "'${PYTHON_BIN}' not found on PATH."
    echo "Install Python 3.10+ or set PYTHON=<your-python> and re-run." >&2
    exit 1
fi

if [ ! -f "${REQS_FILE}" ]; then
    kiss_err "${REQS_FILE} not found."
    exit 1
fi

if [ ! -d "${VENV_DIR}" ]; then
    kiss_log "Creating virtual environment at ${VENV_DIR} ..."
    "${PYTHON_BIN}" -m venv "${VENV_DIR}"
else
    kiss_log "Using existing virtual environment at ${VENV_DIR}"
fi

VENV_PY="${VENV_DIR}/bin/python"

"${VENV_PY}" -m pip install --upgrade pip
"${VENV_PY}" -m pip install -r "${REQS_FILE}"

echo
kiss_log "venv ready at ${VENV_DIR}"
echo "  Activate (optional):  source ${VENV_DIR}/bin/activate"
echo "  Or just run scripts directly; they will auto-prefer ./${VENV_DIR}."
