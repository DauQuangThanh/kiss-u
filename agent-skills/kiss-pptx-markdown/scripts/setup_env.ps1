# Bootstrap a project-local virtualenv for kiss-pptx-markdown (Windows / PowerShell).
#
# Creates .\.venv in the current working directory (so it sits next to your
# .pptx files, not inside the skill folder), then pip-installs the skill's
# Python deps from scripts\requirements.txt.
#
# Run from the workspace where you want the venv to live:
#
#   pwsh <skill-dir>\scripts\setup_env.ps1
#
# Override the Python executable with: $env:PYTHON = "py -3.12"; .\setup_env.ps1
$ErrorActionPreference = "Stop"

$SkillName     = "kiss-pptx-markdown"
$ScriptDir     = Split-Path -Parent $MyInvocation.MyCommand.Definition
$RequirementsFile = Join-Path $ScriptDir "requirements.txt"
$VenvDir       = if ($env:VENV_DIR) { $env:VENV_DIR } else { ".venv" }
$PythonBin     = if ($env:PYTHON)   { $env:PYTHON }   else { "python" }

# Verify Python is available.
$pythonCheck = Get-Command $PythonBin -ErrorAction SilentlyContinue
if (-not $pythonCheck) {
    Write-Error "[$SkillName] '$PythonBin' not found on PATH. Install Python 3.10+ or set `$env:PYTHON and re-run."
    exit 1
}

if (-not (Test-Path $RequirementsFile)) {
    Write-Error "[$SkillName] $RequirementsFile not found."
    exit 1
}

if (-not (Test-Path $VenvDir)) {
    Write-Host "[$SkillName] Creating virtual environment at $VenvDir ..."
    & $PythonBin -m venv $VenvDir
} else {
    Write-Host "[$SkillName] Using existing virtual environment at $VenvDir"
}

$VenvPy = Join-Path $VenvDir "Scripts\python.exe"

& $VenvPy -m pip install --upgrade pip
& $VenvPy -m pip install -r $RequirementsFile

Write-Host ""
Write-Host "[$SkillName] venv ready at $VenvDir"
Write-Host "  Activate (optional):  $VenvDir\Scripts\Activate.ps1"
Write-Host "  Or just run scripts directly; they will auto-prefer .\$VenvDir."
