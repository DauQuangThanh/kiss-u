#!/usr/bin/env pwsh
param([switch]$Auto, [switch]$DryRun, [string]$Answers, [switch]$Help)
$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $PSCommandPath
. (Join-Path $ScriptDir 'common.ps1')
if ($Auto)    { $env:KISS_AUTO = '1' }
if ($DryRun)  { $env:KISS_DRY_RUN = '1' }
if ($Answers) { $env:KISS_ANSWERS = $Answers; Import-KissAnswers -Path $Answers }
if ($Help) {
    @'
Usage: decompose-wbs.ps1 [-Auto] [-Answers FILE] [-DryRun] [-Help]

Decomposes the project WBS into feature stub directories under specs/.
Requires docs/project/project-plan.md to exist.

Answer keys: WBS_DECOMPOSE_LEVEL, WBS_INCLUDE_SUMMARIES, WBS_PREFIX_RESET.
'@ | Write-Host; exit 0
}

$ctx       = Read-Context
$SkillDir  = (Resolve-Path -LiteralPath (Join-Path $ScriptDir '../..')).Path
$Plan      = Join-Path (Join-Path (Join-Path $ctx.REPO_ROOT $ctx.DOCS_DIR) 'project') 'project-plan.md'
$IndexDir  = Get-WorktypeDir -Name 'project'
$IndexOut  = Join-Path $IndexDir 'wbs-index.md'
$Debts     = Join-Path $IndexDir 'wbs-debts.md'

if (-not (Test-Path -LiteralPath $Plan)) {
    Write-Error "project-plan.md not found at $Plan. Run /kiss.project-planning first."
    exit 2
}

$WbsLevel = Resolve-Auto -Key 'WBS_DECOMPOSE_LEVEL' -Default '3'

if ($env:KISS_DRY_RUN -eq '1') {
    Write-Host ("[dry-run] would parse WBS from: {0}" -f $Plan)
    Write-Host ("  decompose_level={0}" -f $WbsLevel)
    Write-Host ("  output_index={0}" -f $IndexOut)
    exit 0
}

if (-not (Confirm-BeforeWrite -Message "Decompose WBS from $Plan into feature stubs.")) {
    Write-Error 'Aborted.'; exit 1
}

$Date      = Get-Date -Format 'yyyy-MM-dd'
$SpecsRoot = Join-Path $ctx.REPO_ROOT $ctx.SPECS_DIR
New-Item -ItemType Directory -Force -Path $SpecsRoot | Out-Null

# Find next NNN prefix
$NextNum = 1
$existing = Get-ChildItem -LiteralPath $SpecsRoot -Directory -ErrorAction SilentlyContinue |
    ForEach-Object { if ($_.Name -match '^(\d+)') { [int]$Matches[1] } }
if ($existing) { $NextNum = ($existing | Measure-Object -Maximum).Maximum + 1 }

$Project = Split-Path $ctx.REPO_ROOT -Leaf
$header = @"
# WBS Feature Index

**Project:** $Project
**Generated:** $Date
**Source:** $Plan

| WBS ID | Title | Feature Directory | Status |
|---|---|---|---|
"@
Set-Content -LiteralPath $IndexOut -Value $header

Write-Host "INFO: WBS decomposition requires AI to parse the WBS from $Plan"
Write-Host "      The AI will extract leaf nodes, generate slugs, and create stubs."
Write-Host ("Wrote index scaffold to {0}" -f $IndexOut)
Write-Host "Next: AI populates index rows and creates spec stubs per WBS leaf"

Write-Extract -ArtefactPath $IndexOut `
    "WBS_LEAF_COUNT=0" `
    "FEATURE_DIRS_CREATED=0" `
    "NEXT_NUM=$NextNum" `
    "WBS_DECOMPOSE_LEVEL=$WbsLevel" `
    "GENERATED_DATE=$Date" | Out-Null
