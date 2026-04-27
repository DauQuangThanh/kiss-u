# Bootstrap a project-local virtualenv for kiss-xlsx-markdown (Windows / PowerShell).
#
# Creates .\.venv in the current working directory (so it sits next to your
# .xlsx files, not inside the skill folder), then pip-installs the skill's
# Python deps from scripts\requirements.txt.
#
# Run from the workspace where you want the venv to live:
#
#   pwsh <skill-dir>\scripts\powershell\setup_env.ps1
#
# Override the Python executable with: $env:PYTHON = "py -3.12"; .\setup_env.ps1
#
# Note: LibreOffice (soffice) is an optional system dependency, only needed
# for --recalc / formula evaluation. Install from https://www.libreoffice.org/.
$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
. (Join-Path $ScriptDir 'common.ps1')

$RequirementsFile = Join-Path $Script:KissSkillScriptsDir "requirements.txt"
$VenvDir   = if ($env:VENV_DIR) { $env:VENV_DIR } else { ".venv" }
$PythonBin = if ($env:PYTHON)   { $env:PYTHON }   else { "python" }

$pythonCheck = Get-Command $PythonBin -ErrorAction SilentlyContinue
if (-not $pythonCheck) {
    Kiss-Err "'$PythonBin' not found on PATH. Install Python 3.10+ or set `$env:PYTHON and re-run."
    exit 1
}

if (-not (Test-Path $RequirementsFile)) {
    Kiss-Err "$RequirementsFile not found."
    exit 1
}

if (-not (Test-Path $VenvDir)) {
    Kiss-Log "Creating virtual environment at $VenvDir ..."
    & $PythonBin -m venv $VenvDir
} else {
    Kiss-Log "Using existing virtual environment at $VenvDir"
}

$VenvPy = Join-Path $VenvDir "Scripts\python.exe"

& $VenvPy -m pip install --upgrade pip
& $VenvPy -m pip install -r $RequirementsFile

Write-Host ""
Kiss-Log "venv ready at $VenvDir"
Write-Host "  Activate (optional):  $VenvDir\Scripts\Activate.ps1"
Write-Host "  Or just run scripts directly; they will auto-prefer .\$VenvDir."
