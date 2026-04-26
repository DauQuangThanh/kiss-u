#!/usr/bin/env pwsh
# kiss-change-control PowerShell parity of add-change.sh.

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
Usage: add-change.ps1 [-Auto] [-Answers FILE] [-DryRun] [-Help]

Appends one change-request entry to docs/project/change-log.md.
Same answer keys as add-change.sh.
'@ | Write-Host
    exit 0
}

$ctx = Read-Context
$SkillDir   = (Resolve-Path -LiteralPath (Join-Path $ScriptDir '..\..')).Path
$ProjectDir = Join-Path (Join-Path $ctx.REPO_ROOT $ctx.DOCS_DIR) 'project'
$Log        = Join-Path $ProjectDir 'change-log.md'
$DebtsFile  = Join-Path $ProjectDir 'pm-debts.md'

$Description     = Resolve-Auto -Key 'CR_DESCRIPTION'       -Default ''
$Requester       = Resolve-Auto -Key 'CR_REQUESTER'         -Default ''
$Reason          = Resolve-Auto -Key 'CR_REASON'            -Default ''
$Solution        = Resolve-Auto -Key 'CR_PROPOSED_SOLUTION' -Default ''
$ScopeImpact     = Resolve-Auto -Key 'CR_SCOPE_IMPACT'      -Default 'L'
$ScheduleImpact  = Resolve-Auto -Key 'CR_SCHEDULE_IMPACT'   -Default 'L'
$BudgetImpact    = Resolve-Auto -Key 'CR_BUDGET_IMPACT'     -Default 'L'
$QualityImpact   = Resolve-Auto -Key 'CR_QUALITY_IMPACT'    -Default 'L'
$Priority        = Resolve-Auto -Key 'CR_PRIORITY'          -Default '🟢 Medium'
$Status          = Resolve-Auto -Key 'CR_STATUS'            -Default 'Pending'
$ApprovedBy      = Resolve-Auto -Key 'CR_APPROVED_BY'       -Default ''
$DecisionDate    = Resolve-Auto -Key 'CR_DECISION_DATE'     -Default ''
$DecisionReason  = Resolve-Auto -Key 'CR_DECISION_REASON'   -Default ''

function Norm-HML([string]$v) { if ($v -in @('H','M','L')) { $v } else { 'L' } }
$ScopeImpact    = Norm-HML $ScopeImpact
$ScheduleImpact = Norm-HML $ScheduleImpact
$BudgetImpact   = Norm-HML $BudgetImpact
$QualityImpact  = Norm-HML $QualityImpact

if ($Status -notin @('Pending','Approved','Rejected','On Hold','Closed')) {
    $Status = 'Pending'
}

if ($env:KISS_DRY_RUN -eq '1') {
    Write-Host ("[dry-run] would append CR to: {0}" -f $Log)
    Write-Host ("[dry-run] description:   {0}" -f $(if ($Description) { $Description } else { '<missing>' }))
    Write-Host ("[dry-run] requester:     {0}" -f $(if ($Requester) { $Requester } else { '<missing>' }))
    Write-Host ("[dry-run] priority:      {0}" -f $Priority)
    Write-Host ("[dry-run] impact S/S/B/Q: {0}/{1}/{2}/{3}" -f $ScopeImpact, $ScheduleImpact, $BudgetImpact, $QualityImpact)
    Write-Host ("[dry-run] status:        {0}" -f $Status)
    exit 0
}

if (-not (Confirm-BeforeWrite -Message "Append change-request to $Log.")) {
    Write-Error 'Aborted.'
    exit 1
}

New-Item -ItemType Directory -Force -Path $ProjectDir | Out-Null

if (-not (Test-Path -LiteralPath $Log)) {
    $ProjectName = if ($ctx.CURRENT_FEATURE) { $ctx.CURRENT_FEATURE } else { 'project' }
    $planExtract = Join-Path $ProjectDir 'project-plan.extract'
    if (Test-Path -LiteralPath $planExtract) {
        $line = Get-Content -LiteralPath $planExtract | Where-Object { $_ -match '^PROJECT_NAME=' } | Select-Object -First 1
        if ($line) { $ProjectName = ($line -replace '^PROJECT_NAME=', '') }
    }
    $template = Join-Path $SkillDir 'templates\change-log-template.md'
    $content = Get-Content -LiteralPath $template -Raw
    $content = $content.Replace('{project_name}', $ProjectName)
    $content = $content.Replace('{date}', (Get-Date -Format 'yyyy-MM-dd'))
    $content = $content.Replace('{feature}', $(if ($ctx.CURRENT_FEATURE) { $ctx.CURRENT_FEATURE } else { '<none>' }))
    # Strip placeholder block
    $lines = $content -split "`n"
    $out = @(); $skip = $false
    foreach ($l in $lines) {
        if ($l -match '^### CR-NN:') { $skip = $true; continue }
        if ($skip -and $l -match '^---$') { $skip = $false; continue }
        if (-not $skip) { $out += $l }
    }
    Set-Content -LiteralPath $Log -Value ($out -join "`n")
}

# Next id
$next = 1
$existing = Select-String -LiteralPath $Log -Pattern '^### CR-(\d+)' -AllMatches -ErrorAction SilentlyContinue |
    ForEach-Object { $_.Matches } | ForEach-Object { [int]$_.Groups[1].Value }
if ($existing) { $next = ($existing | Measure-Object -Maximum).Maximum + 1 }
$crId = '{0}-{1:D2}' -f 'CR', $next
$today = Get-Date -Format 'yyyy-MM-dd'

$block = @"

### $crId`: $(if ($Description) { $Description } else { '<TBD>' })

**Requested by:** $(if ($Requester) { $Requester } else { '<TBD>' })
**Request date:** $today
**Priority:** $Priority
**Status:** $Status

**Scope impact:** $ScopeImpact
**Schedule impact:** $ScheduleImpact
**Budget impact:** $BudgetImpact
**Quality impact:** $QualityImpact

**Reason for request:** $(if ($Reason) { $Reason } else { '<TBD>' })
**Proposed solution:** $(if ($Solution) { $Solution } else { '<TBD>' })

**Decision:** $Status
**Decision date:** $(if ($DecisionDate) { $DecisionDate } else { 'TBD' })
**Decided by:** $(if ($ApprovedBy) { $ApprovedBy } else { 'TBD' })
**Decision reason:** $(if ($DecisionReason) { $DecisionReason } else { '<TBD>' })
"@

if ($Status -eq 'Approved') {
    $block += @"

**Implementation plan:**

1. <step 1>
2. <step 2>
3. <step 3>
"@
}

$block += @"

**Completion date:** TBD

---
"@

Add-Content -LiteralPath $Log -Value $block

# Counts
$text = Get-Content -LiteralPath $Log -Raw
$total    = ([regex]::Matches($text, '(?m)^### CR-')).Count
$pending  = ([regex]::Matches($text, '(?m)^\*\*Status:\*\* Pending')).Count
$approved = ([regex]::Matches($text, '(?m)^\*\*Status:\*\* Approved')).Count
$rejected = ([regex]::Matches($text, '(?m)^\*\*Status:\*\* Rejected')).Count

Write-Extract -ArtefactPath $Log `
    "TOTAL_CRS=$total" `
    "PENDING=$pending" `
    "APPROVED=$approved" `
    "REJECTED=$rejected" `
    "LAST_ADDED=$crId" | Out-Null

Write-Host ("Appended {0} ({1}, {2}) to {3}" -f $crId, $Status, $Priority, $Log)

if (-not $Description) {
    Append-Debt -File $DebtsFile -Prefix 'PMDEBT' -Body "CR $crId has no description (Area: Scope, Owner: user, Priority: 🔴 Blocking)" | Out-Null
}
if (-not $Requester) {
    Append-Debt -File $DebtsFile -Prefix 'PMDEBT' -Body "CR $crId has no requester recorded (Area: Scope, Owner: user, Priority: 🟡 Important)" | Out-Null
}
if ($Status -eq 'Approved' -and -not $ApprovedBy) {
    Append-Debt -File $DebtsFile -Prefix 'PMDEBT' -Body "CR $crId marked Approved but has no approver on record (Area: Governance, Owner: user, Priority: 🟡 Important)" | Out-Null
}
