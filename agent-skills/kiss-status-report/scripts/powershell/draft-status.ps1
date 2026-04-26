#!/usr/bin/env pwsh
# kiss-status-report PowerShell parity of draft-status.sh.

param(
    [switch]$Auto,
    [switch]$DryRun,
    [string]$Answers,
    [switch]$Help
)

$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $PSCommandPath
. (Join-Path $ScriptDir 'common.ps1')

if ($Auto)    { $env:KISS_AUTO = '1' }
if ($DryRun)  { $env:KISS_DRY_RUN = '1' }
if ($Answers) {
    $env:KISS_ANSWERS = $Answers
    Import-KissAnswers -Path $Answers
}

if ($Help) {
    @'
Usage: draft-status.ps1 [-Auto] [-Answers FILE] [-DryRun] [-Help]

Scaffolds docs/project/status-YYYY-MM-DD.md from the template.
'@ | Write-Host
    exit 0
}

$ctx = Read-Context
$SkillDir   = (Resolve-Path -LiteralPath (Join-Path $ScriptDir '..\..')).Path
$ProjectDir = Join-Path (Join-Path $ctx.REPO_ROOT $ctx.DOCS_DIR) 'project'
$DebtsFile  = Join-Path $ProjectDir 'pm-debts.md'

$Today   = Get-Date -Format 'yyyy-MM-dd'
$WeekAgo = (Get-Date).AddDays(-7).ToString('yyyy-MM-dd')

$PeriodStart    = Resolve-Auto -Key 'STATUS_PERIOD_START'    -Default $WeekAgo
$PeriodEnd      = Resolve-Auto -Key 'STATUS_PERIOD_END'      -Default $Today
$ReportDate     = Resolve-Auto -Key 'STATUS_REPORT_DATE'     -Default $Today
$Rag            = Resolve-Auto -Key 'STATUS_RAG'             -Default ''
$BudgetVariance = Resolve-Auto -Key 'STATUS_BUDGET_VARIANCE' -Default 'on-track'
$Accomplishments= Resolve-Auto -Key 'STATUS_ACCOMPLISHMENTS' -Default ''
$Planned        = Resolve-Auto -Key 'STATUS_PLANNED'         -Default ''

# Auto-derive RAG from risk-register extract when not set.
if (-not $Rag) {
    $Rag = 'green'
    $riskExtract = Join-Path $ProjectDir 'risk-register.extract'
    if (Test-Path -LiteralPath $riskExtract) {
        $redLine   = Get-Content -LiteralPath $riskExtract | Where-Object { $_ -match '^RED=' }   | Select-Object -First 1
        $amberLine = Get-Content -LiteralPath $riskExtract | Where-Object { $_ -match '^AMBER=' } | Select-Object -First 1
        $red   = if ($redLine)   { [int]($redLine   -replace '^RED=','')   } else { 0 }
        $amber = if ($amberLine) { [int]($amberLine -replace '^AMBER=','') } else { 0 }
        if ($amber -gt 0) { $Rag = 'amber' }
        if ($red   -gt 0) { $Rag = 'red' }
    }
}

$RagBand = switch ($Rag) {
    'red'   { '🔴 RED' }
    'amber' { '🟡 AMBER' }
    default { '🟢 GREEN' }
}

$ReportFile = Join-Path $ProjectDir ("status-{0}.md" -f $ReportDate)

if ($env:KISS_DRY_RUN -eq '1') {
    Write-Host ("[dry-run] would write: {0}" -f $ReportFile)
    Write-Host ("[dry-run] period:      {0} to {1}" -f $PeriodStart, $PeriodEnd)
    Write-Host ("[dry-run] rag:         {0}" -f $RagBand)
    Write-Host ("[dry-run] budget:      {0}" -f $BudgetVariance)
    exit 0
}

if (Test-Path -LiteralPath $ReportFile) {
    Write-Error ("Status report for {0} already exists: {1}. Pick a different STATUS_REPORT_DATE." -f $ReportDate, $ReportFile)
    exit 2
}

if (-not (Confirm-BeforeWrite -Message "Scaffold status report at $ReportFile.")) {
    Write-Error 'Aborted.'
    exit 1
}

New-Item -ItemType Directory -Force -Path $ProjectDir | Out-Null

$ProjectName = if ($ctx.CURRENT_FEATURE) { $ctx.CURRENT_FEATURE } else { 'project' }
$planExtract = Join-Path $ProjectDir 'project-plan.extract'
if (Test-Path -LiteralPath $planExtract) {
    $line = Get-Content -LiteralPath $planExtract | Where-Object { $_ -match '^PROJECT_NAME=' } | Select-Object -First 1
    if ($line) { $ProjectName = ($line -replace '^PROJECT_NAME=', '') }
}

$Template = Join-Path $SkillDir 'templates\status-report-template.md'
$content = Get-Content -LiteralPath $Template -Raw
$content = $content.Replace('{project_name}', $ProjectName)
$content = $content.Replace('{feature}', $(if ($ctx.CURRENT_FEATURE) { $ctx.CURRENT_FEATURE } else { '<none>' }))
$content = $content.Replace('{period_start}', $PeriodStart)
$content = $content.Replace('{period_end}', $PeriodEnd)
$content = $content.Replace('{report_date}', $ReportDate)
$content = $content.Replace('{rag_band}', $RagBand)
$content = $content.Replace('{budget_variance}', $BudgetVariance)
Set-Content -LiteralPath $ReportFile -Value $content

Write-Extract -ArtefactPath $ReportFile `
    "REPORT_DATE=$ReportDate" `
    "PERIOD_START=$PeriodStart" `
    "PERIOD_END=$PeriodEnd" `
    "RAG=$Rag" `
    "BUDGET_VARIANCE=$BudgetVariance" | Out-Null

Write-Host ("Wrote {0}" -f $ReportFile)

if (-not $Accomplishments) {
    Append-Debt -File $DebtsFile -Prefix 'PMDEBT' -Body "Status report for $ReportDate has no accomplishments recorded (Area: Comms, Priority: 🟢 Can wait)" | Out-Null
}
if (-not $Planned) {
    Append-Debt -File $DebtsFile -Prefix 'PMDEBT' -Body "Status report for $ReportDate has no planned activities for next period (Area: Schedule, Priority: 🟡 Important)" | Out-Null
}
