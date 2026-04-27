# Shared helpers for kiss-xlsx-markdown action scripts (PowerShell).
#
# These skills are standalone Office round-trip tools: they don't read
# .kiss/context.yml, don't write under docs/<work-type>/, and don't
# need the full kiss helper surface area. Dot-sourcing this file gives
# the action scripts a tiny, consistent set of log helpers and the
# location of the bundle's Python scripts so setup_env / wrappers can
# resolve requirements.txt and venv_bootstrap.py reliably.

$Script:KissSkillScriptsDir = (Resolve-Path (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Definition) '..')).Path
$Script:KissSkillName = 'kiss-xlsx-markdown'

function Kiss-Log  { param([string]$Message) Write-Host  "[$Script:KissSkillName] $Message" }
function Kiss-Warn { param([string]$Message) Write-Host  "[$Script:KissSkillName] warning: $Message" -ForegroundColor Yellow }
function Kiss-Err  { param([string]$Message) Write-Error "[$Script:KissSkillName] $Message" }
