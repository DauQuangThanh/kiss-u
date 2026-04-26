#!/usr/bin/env pwsh
param(
    [switch]$Auto, [switch]$DryRun, [string]$Answers, [switch]$Help
)
$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $PSCommandPath
. (Join-Path $ScriptDir 'common.ps1')

if ($Auto)    { $env:KISS_AUTO = '1' }
if ($DryRun)  { $env:KISS_DRY_RUN = '1' }
if ($Answers) { $env:KISS_ANSWERS = $Answers; Import-KissAnswers -Path $Answers }

if ($Help) {
    "Usage: draft-roadmap.ps1 [-Auto] [-Answers FILE] [-DryRun] [-Help]`nScaffolds docs/product/roadmap.md." | Write-Host
    exit 0
}

$ctx = Read-Context
$SkillDir = (Resolve-Path -LiteralPath (Join-Path $ScriptDir '..\..')).Path
$Dir      = Join-Path (Join-Path $ctx.REPO_ROOT $ctx.DOCS_DIR) 'product'
$Out      = Join-Path $Dir 'roadmap.md'

$Style    = Resolve-Auto -Key 'RM_WINDOW_STYLE' -Default 'nnl'
$NowWeeks = [int](Resolve-Auto -Key 'RM_NOW_WEEKS'  -Default '4')
$NxtWeeks = [int](Resolve-Auto -Key 'RM_NEXT_WEEKS' -Default '12')

if ($Style -eq 'date') {
    $NowRange  = "next $NowWeeks weeks"
    $NextRange = "weeks $($NowWeeks+1)–$($NowWeeks+$NxtWeeks)"
} else {
    $NowRange  = 'in flight'
    $NextRange = 'up next'
}

if ($env:KISS_DRY_RUN -eq '1') {
    Write-Host ("[dry-run] would write: {0}" -f $Out)
    exit 0
}

if (-not (Confirm-BeforeWrite -Message "Scaffold roadmap at $Out.")) { Write-Error 'Aborted.'; exit 1 }

New-Item -ItemType Directory -Force -Path $Dir | Out-Null
if (Test-Path -LiteralPath $Out) { Write-Error "Roadmap already exists: $Out"; exit 2 }

$tpl = Join-Path $SkillDir 'templates\roadmap-template.md'
$c = Get-Content -LiteralPath $tpl -Raw
$c = $c.Replace('{date}', (Get-Date -Format 'yyyy-MM-dd')).Replace('{window_style}', $Style).Replace('{now_range}', $NowRange).Replace('{next_range}', $NextRange)
Set-Content -LiteralPath $Out -Value $c

Write-Extract -ArtefactPath $Out "STYLE=$Style" "NOW_RANGE=$NowRange" "NEXT_RANGE=$NextRange" | Out-Null
Write-Host ("Wrote {0}" -f $Out)
