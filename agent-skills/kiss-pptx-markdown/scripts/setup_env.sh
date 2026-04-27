#!/usr/bin/env bash
# Bootstrap a project-local virtualenv for kiss-pptx-markdown.
#
# Creates ./.venv in the *current working directory* (so it sits next to your
# .pptx files, not inside the skill folder), then pip-installs the skill's
# Python deps from scripts/requirements.txt.
#
# Run from the workspace where you want the venv to live:
#
#   bash <skill-dir>/scripts/setup_env.sh
#
# Override the Python executable with: PYTHON=python3.12 bash setup_env.sh
set -euo pipefail

SKILL_NAME="kiss-pptx-markdown"
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
REQS_FILE="${SCRIPT_DIR}/requirements.txt"
VENV_DIR="${VENV_DIR:-.venv}"
PYTHON_BIN="${PYTHON:-python3}"

if ! command -v "${PYTHON_BIN}" > /dev/null 2>&1; then
    echo "[${SKILL_NAME}] error: '${PYTHON_BIN}' not found on PATH." >&2
    echo "Install Python 3.10+ or set PYTHON=<your-python> and re-run." >&2
    exit 1
fi

if [ ! -f "${REQS_FILE}" ]; then
    echo "[${SKILL_NAME}] error: ${REQS_FILE} not found." >&2
    exit 1
fi

if [ ! -d "${VENV_DIR}" ]; then
    echo "[${SKILL_NAME}] Creating virtual environment at ${VENV_DIR} ..."
    "${PYTHON_BIN}" -m venv "${VENV_DIR}"
else
    echo "[${SKILL_NAME}] Using existing virtual environment at ${VENV_DIR}"
fi

VENV_PY="${VENV_DIR}/bin/python"

"${VENV_PY}" -m pip install --upgrade pip
"${VENV_PY}" -m pip install -r "${REQS_FILE}"

echo
echo "[${SKILL_NAME}] venv ready at ${VENV_DIR}"
echo "  Activate (optional):  source ${VENV_DIR}/bin/activate"
echo "  Or just run scripts directly; they will auto-prefer ./${VENV_DIR}."
