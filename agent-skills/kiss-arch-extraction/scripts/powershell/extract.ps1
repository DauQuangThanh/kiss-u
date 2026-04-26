#!/usr/bin/env pwsh
param([switch]$Auto, [switch]$DryRun, [string]$Answers, [switch]$Help)
$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $PSCommandPath
. (Join-Path $ScriptDir 'common.ps1')
if ($Auto)    { $env:KISS_AUTO = '1' }
if ($DryRun)  { $env:KISS_DRY_RUN = '1' }
if ($Answers) { $env:KISS_ANSWERS = $Answers; Import-KissAnswers -Path $Answers }
if ($Help) { "Usage: extract.ps1 -Auto." | Write-Host; exit 0 }
$ctx = Read-Context
$SkillDir = (Resolve-Path -LiteralPath (Join-Path $ScriptDir '..\..')).Path
$Dir = Join-Path (Join-Path $ctx.REPO_ROOT $ctx.DOCS_DIR) 'architecture'
$Out = Join-Path $Dir 'extracted.md'
if ($env:KISS_DRY_RUN -eq '1') { Write-Host ("[dry-run] would write: {0}" -f $Out); exit 0 }
if (Test-Path -LiteralPath $Out) { Write-Error "Extracted arch exists: $Out"; exit 2 }
if (-not (Confirm-BeforeWrite -Message "Scaffold extracted-architecture doc at $Out.")) { Write-Error 'Aborted.'; exit 1 }
New-Item -ItemType Directory -Force -Path $Dir | Out-Null
$tpl = Join-Path $SkillDir 'templates\extracted-template.md'
$c = Get-Content -LiteralPath $tpl -Raw
$c = $c.Replace('{date}', (Get-Date -Format 'yyyy-MM-dd'))
Set-Content -LiteralPath $Out -Value $c
Write-Extract -ArtefactPath $Out "DATE=$(Get-Date -Format 'yyyy-MM-dd')" | Out-Null
Write-Host ("Wrote {0}" -f $Out)
