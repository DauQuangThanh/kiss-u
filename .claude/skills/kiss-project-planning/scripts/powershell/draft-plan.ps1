#!/usr/bin/env pwsh
# PowerShell parity of draft-plan.sh. See that file for documentation.

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
Usage: draft-plan.ps1 [-Auto] [-Answers FILE] [-DryRun] [-Help]

Scaffolds the project plan artefact at docs/project/project-plan.md
from templates/project-plan-template.md. When PM_INCLUDE_COMMS_PLAN=true
(or provided interactively), also scaffolds docs/project/communication-plan.md.
'@ | Write-Host
    exit 0
}

$ctx = Read-Context
$SkillDir   = (Resolve-Path -LiteralPath (Join-Path $ScriptDir '..\..')).Path
$ProjectDir = Join-Path (Join-Path $ctx.REPO_ROOT $ctx.DOCS_DIR) 'project'
$PlanFile   = Join-Path $ProjectDir 'project-plan.md'
$CommsFile  = Join-Path $ProjectDir 'communication-plan.md'
$DebtsFile  = Join-Path $ProjectDir 'pm-debts.md'

$ProjectName   = Resolve-Auto -Key 'PM_PROJECT_NAME'   -Default (if ($ctx.CURRENT_FEATURE) { $ctx.CURRENT_FEATURE } else { 'project' })
$Methodology   = Resolve-Auto -Key 'PM_METHODOLOGY'    -Default 'scrum'
$StartDate     = Resolve-Auto -Key 'PM_START_DATE'     -Default (Get-Date -Format 'yyyy-MM-dd')
$TargetGoLive  = Resolve-Auto -Key 'PM_TARGET_GO_LIVE' -Default ''
$TeamSize      = Resolve-Auto -Key 'PM_TEAM_SIZE'      -Default ''
$Sponsor       = Resolve-Auto -Key 'PM_SPONSOR'        -Default ''
$IncludeComms  = Resolve-Auto -Key 'PM_INCLUDE_COMMS_PLAN' -Default 'false'

if ($env:KISS_DRY_RUN -eq '1') {
    Write-Host ("[dry-run] would write: {0}" -f $PlanFile)
    if ($IncludeComms -eq 'true') {
        Write-Host ("[dry-run] would write: {0}" -f $CommsFile)
    }
    Write-Host ("[dry-run] project_name:   {0}" -f $ProjectName)
    Write-Host ("[dry-run] methodology:    {0}" -f $Methodology)
    Write-Host ("[dry-run] start_date:     {0}" -f $StartDate)
    Write-Host ("[dry-run] target_go_live: {0}" -f $(if ($TargetGoLive) { $TargetGoLive } else { '<missing>' }))
    Write-Host ("[dry-run] team_size:      {0}" -f $(if ($TeamSize) { $TeamSize } else { '<missing>' }))
    Write-Host ("[dry-run] sponsor:        {0}" -f $(if ($Sponsor) { $Sponsor } else { '<missing>' }))
    Write-Host ("[dry-run] include_comms:  {0}" -f $IncludeComms)
    exit 0
}

if (-not (Confirm-BeforeWrite -Message "Scaffold project plan at $PlanFile.")) {
    Write-Error 'Aborted.'
    exit 1
}

New-Item -ItemType Directory -Force -Path $ProjectDir | Out-Null

if (Test-Path -LiteralPath $PlanFile) {
    Write-Error ("Project plan already exists: {0}. Refusing to overwrite." -f $PlanFile)
    exit 2
}

$Template = Join-Path $SkillDir 'templates\project-plan-template.md'
$content  = Get-Content -LiteralPath $Template -Raw
$content  = $content.Replace('{project_name}', $ProjectName)
$content  = $content.Replace('{date}', $StartDate)
$content  = $content.Replace('{methodology}', $Methodology)
$content  = $content.Replace('{sponsor}', $(if ($Sponsor) { $Sponsor } else { '<TBD>' }))
$content  = $content.Replace('{feature}', $(if ($ctx.CURRENT_FEATURE) { $ctx.CURRENT_FEATURE } else { '<none>' }))
Set-Content -LiteralPath $PlanFile -Value $content

Write-Extract -ArtefactPath $PlanFile `
    "PROJECT_NAME=$ProjectName" `
    "METHODOLOGY=$Methodology" `
    "START_DATE=$StartDate" `
    "TARGET_GO_LIVE=$TargetGoLive" `
    "TEAM_SIZE=$TeamSize" `
    "SPONSOR=$Sponsor" | Out-Null

Write-Host ("Wrote {0}" -f $PlanFile)

if ($IncludeComms -eq 'true') {
    $CommsTemplate = Join-Path $SkillDir 'templates\communication-plan-template.md'
    $c = Get-Content -LiteralPath $CommsTemplate -Raw
    $c = $c.Replace('{project_name}', $ProjectName).Replace('{date}', $StartDate)
    Set-Content -LiteralPath $CommsFile -Value $c
    Write-Host ("Wrote {0}" -f $CommsFile)
}

if (-not $TargetGoLive) {
    Append-Debt -File $DebtsFile -Prefix 'PMDEBT' -Body 'Target go-live date is not set — required to compute critical path (Area: Schedule, Owner: user, Priority: 🔴 Blocking)' | Out-Null
}
if (-not $TeamSize) {
    Append-Debt -File $DebtsFile -Prefix 'PMDEBT' -Body 'Team size is not set — required to estimate capacity (Area: Resource, Owner: user, Priority: 🟡 Important)' | Out-Null
}
if (-not $Sponsor) {
    Append-Debt -File $DebtsFile -Prefix 'PMDEBT' -Body 'Project sponsor is not set — required for escalation path (Area: Stakeholders, Owner: user, Priority: 🟡 Important)' | Out-Null
}

if (Test-Path -LiteralPath $DebtsFile) {
    Write-Host ("Logged debts to {0} (review before finalising the plan)." -f $DebtsFile)
}
