#!/usr/bin/env pwsh
# kiss-risk-register PowerShell parity of add-risk.sh.

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
Usage: add-risk.ps1 [-Auto] [-Answers FILE] [-DryRun] [-Help]

Appends one risk entry to docs/project/risk-register.md.
Same answer keys as add-risk.sh.
'@ | Write-Host
    exit 0
}

$ctx = Read-Context
$SkillDir   = (Resolve-Path -LiteralPath (Join-Path $ScriptDir '..\..')).Path
$ProjectDir = Join-Path (Join-Path $ctx.REPO_ROOT $ctx.DOCS_DIR) 'project'
$Register   = Join-Path $ProjectDir 'risk-register.md'
$DebtsFile  = Join-Path $ProjectDir 'pm-debts.md'

$Description = Resolve-Auto -Key 'RISK_DESCRIPTION' -Default ''
$Category    = Resolve-Auto -Key 'RISK_CATEGORY'    -Default 'Other'
$Likelihood  = [int](Resolve-Auto -Key 'RISK_LIKELIHOOD' -Default '3')
$Impact      = [int](Resolve-Auto -Key 'RISK_IMPACT'      -Default '3')
$Owner       = Resolve-Auto -Key 'RISK_OWNER'       -Default ''
$Mitigation  = Resolve-Auto -Key 'RISK_MITIGATION'  -Default ''
$Contingency = Resolve-Auto -Key 'RISK_CONTINGENCY' -Default ''
$Status      = Resolve-Auto -Key 'RISK_STATUS'      -Default 'Active'

if ($Likelihood -lt 1 -or $Likelihood -gt 5) { $Likelihood = 3 }
if ($Impact     -lt 1 -or $Impact     -gt 5) { $Impact     = 3 }
$Score = $Likelihood * $Impact
$Band = if ($Score -ge 15) { '🔴 Red' } elseif ($Score -ge 8) { '🟡 Amber' } else { '🟢 Green' }

if ($env:KISS_DRY_RUN -eq '1') {
    Write-Host ("[dry-run] would append risk to: {0}" -f $Register)
    Write-Host ("[dry-run] description:  {0}" -f $(if ($Description) { $Description } else { '<missing>' }))
    Write-Host ("[dry-run] category:     {0}" -f $Category)
    Write-Host ("[dry-run] score/band:   {0}  {1}" -f $Score, $Band)
    Write-Host ("[dry-run] owner:        {0}" -f $(if ($Owner) { $Owner } else { '<missing>' }))
    Write-Host ("[dry-run] mitigation:   {0}" -f $(if ($Mitigation) { $Mitigation } else { '<missing>' }))
    Write-Host ("[dry-run] status:       {0}" -f $Status)
    exit 0
}

if (-not (Confirm-BeforeWrite -Message "Append risk to $Register.")) {
    Write-Error 'Aborted.'
    exit 1
}

New-Item -ItemType Directory -Force -Path $ProjectDir | Out-Null

if (-not (Test-Path -LiteralPath $Register)) {
    $ProjectName = if ($ctx.CURRENT_FEATURE) { $ctx.CURRENT_FEATURE } else { 'project' }
    $planExtract = Join-Path $ProjectDir 'project-plan.extract'
    if (Test-Path -LiteralPath $planExtract) {
        $line = Get-Content -LiteralPath $planExtract | Where-Object { $_ -match '^PROJECT_NAME=' } | Select-Object -First 1
        if ($line) { $ProjectName = ($line -replace '^PROJECT_NAME=', '') }
    }
    $template = Join-Path $SkillDir 'templates\risk-register-template.md'
    $content = Get-Content -LiteralPath $template -Raw
    $content = $content.Replace('{project_name}', $ProjectName).Replace('{date}', (Get-Date -Format 'yyyy-MM-dd'))
    $content = $content.Replace('{feature}', $(if ($ctx.CURRENT_FEATURE) { $ctx.CURRENT_FEATURE } else { '<none>' }))
    # Strip the placeholder RISK-NN block
    $lines = $content -split "`n"
    $out = @(); $skip = $false
    foreach ($l in $lines) {
        if ($l -match '^### RISK-NN:') { $skip = $true; continue }
        if ($skip -and $l -match '^---$') { $skip = $false; continue }
        if (-not $skip) { $out += $l }
    }
    Set-Content -LiteralPath $Register -Value ($out -join "`n")
}

# Next RISK id
$next = 1
$existing = Select-String -LiteralPath $Register -Pattern '^### RISK-(\d+)' -AllMatches -ErrorAction SilentlyContinue |
    ForEach-Object { $_.Matches } | ForEach-Object { [int]$_.Groups[1].Value }
if ($existing) { $next = ($existing | Measure-Object -Maximum).Maximum + 1 }
$rid = '{0}-{1:D2}' -f 'RISK', $next

$today = Get-Date -Format 'yyyy-MM-dd'
$block = @"

### $rid`: $(if ($Description) { $Description } else { '<TBD>' })

**Category:** $Category
**Likelihood:** $Likelihood/5
**Impact:** $Impact/5
**Score:** $Score ($Band)
**Description:** $(if ($Description) { $Description } else { '<TBD>' })
**Mitigation:** $(if ($Mitigation) { $Mitigation } else { '<TBD>' })
**Contingency:** $(if ($Contingency) { $Contingency } else { '<none>' })
**Owner:** $(if ($Owner) { $Owner } else { '<TBD>' })
**Status:** $Status
**Last updated:** $today

---
"@
Add-Content -LiteralPath $Register -Value $block

# Recompute counts
$text = Get-Content -LiteralPath $Register -Raw
$red   = ([regex]::Matches($text, '\*\*Score:\*\*.*🔴 Red')).Count
$amber = ([regex]::Matches($text, '\*\*Score:\*\*.*🟡 Amber')).Count
$green = ([regex]::Matches($text, '\*\*Score:\*\*.*🟢 Green')).Count
$total = ([regex]::Matches($text, '^### RISK-', 'Multiline')).Count

Write-Extract -ArtefactPath $Register `
    "TOTAL_RISKS=$total" `
    "RED=$red" `
    "AMBER=$amber" `
    "GREEN=$green" `
    "LAST_ADDED=$rid" | Out-Null

Write-Host ("Appended {0} ({1} {2}) to {3}" -f $rid, $Score, $Band, $Register)

if (-not $Description) {
    Append-Debt -File $DebtsFile -Prefix 'PMDEBT' -Body "Risk $rid has no description (Area: Risk, Owner: user, Priority: 🔴 Blocking)" | Out-Null
}
if (-not $Owner) {
    Append-Debt -File $DebtsFile -Prefix 'PMDEBT' -Body "Risk $rid has no owner (Area: Risk, Owner: user, Priority: 🟡 Important)" | Out-Null
}
if (-not $Mitigation) {
    Append-Debt -File $DebtsFile -Prefix 'PMDEBT' -Body "Risk $rid has no mitigation plan (Area: Risk, Owner: user, Priority: 🟡 Important)" | Out-Null
}
