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
Usage: build-rtm.ps1 [-Auto] [-Answers FILE] [-DryRun] [-Help]

Builds or updates the Requirements Traceability Matrix at
docs/analysis/traceability-matrix.md.

Answer keys: RTM_COVERAGE_THRESHOLD, RTM_INCLUDE_NFRS.
'@ | Write-Host; exit 0
}

$ctx        = Read-Context
$SkillDir   = (Resolve-Path -LiteralPath (Join-Path $ScriptDir '../..')).Path
$AnalysisDir= Get-WorktypeDir -Name 'analysis'
$Out        = Join-Path $AnalysisDir 'traceability-matrix.md'
$Debts      = Join-Path $AnalysisDir 'rtm-debts.md'
$Srs        = Join-Path (Join-Path $ctx.REPO_ROOT $ctx.DOCS_DIR) 'architecture\srs.md'

$Threshold  = Resolve-Auto -Key 'RTM_COVERAGE_THRESHOLD' -Default '80'
$InclNfrs   = Resolve-Auto -Key 'RTM_INCLUDE_NFRS'       -Default 'true'

if (-not (Test-Path -LiteralPath $Srs)) {
    Write-Error "srs.md not found at $Srs. Run /kiss.srs first."
    exit 2
}

$srsContent = Get-Content -LiteralPath $Srs -Raw
$totalFr    = ([regex]::Matches($srsContent, 'FR-\d+')).Count
$totalNfr   = 0
if ($InclNfrs -eq 'true') {
    $totalNfr = ([regex]::Matches($srsContent, 'NFR-\d+')).Count
}
$total = $totalFr + $totalNfr

if ($total -eq 0) {
    Append-Debt -File $Debts -Prefix 'RTMDEBT' -Body 'SRS has no numbered FR/NFR entries — populate srs.md before building RTM' | Out-Null
    Write-Warning "No FR/NFR identifiers found in $Srs. Wrote debt entry."
}

if ($env:KISS_DRY_RUN -eq '1') {
    Write-Host ("[dry-run] would write: {0}" -f $Out)
    Write-Host ("  total_requirements={0}  threshold={1}%" -f $total, $Threshold)
    exit 0
}

if (-not (Confirm-BeforeWrite -Message "Write RTM to $Out ($total requirements detected).")) {
    Write-Error 'Aborted.'; exit 1
}

$Project = Split-Path $ctx.REPO_ROOT -Leaf
$Date    = Get-Date -Format 'yyyy-MM-dd'
$tpl     = Get-Content -LiteralPath (Join-Path $SkillDir 'templates\rtm-template.md') -Raw
$tpl     = $tpl.Replace('{project}', $Project).Replace('{revision}', '1.0').Replace('{date}', $Date)
$tpl     = $tpl.Replace('{total}', $total).Replace('{rows}', '<!-- AI: populate rows from SRS FR/NFR scan -->')
Set-Content -LiteralPath $Out -Value $tpl

Write-Extract -ArtefactPath $Out `
    "RTM_REVISION=1.0" `
    "TOTAL_REQS=$total" `
    "COVERAGE_PCT=0" `
    "UNCOVERED_REQS=$total" `
    "COVERAGE_THRESHOLD=$Threshold" `
    "LAST_UPDATED=$Date" | Out-Null

Write-Host ("Wrote {0} (coverage data requires AI population of table rows)" -f $Out)
