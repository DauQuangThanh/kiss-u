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
    "Usage: draft-sprint.ps1 [-Auto] [-Answers FILE] [-DryRun] [-Help]`nScaffolds docs/agile/sprint-NN-plan.md." | Write-Host
    exit 0
}

$ctx = Read-Context
$SkillDir = (Resolve-Path -LiteralPath (Join-Path $ScriptDir '..\..')).Path
$Dir      = Join-Path (Join-Path $ctx.REPO_ROOT $ctx.DOCS_DIR) 'agile'
$Debts    = Join-Path $Dir 'agile-debts.md'

# auto-increment sprint number
$next = 1
if (Test-Path -LiteralPath $Dir) {
    $nums = Get-ChildItem -LiteralPath $Dir -Filter 'sprint-*-plan.md' -ErrorAction SilentlyContinue |
        ForEach-Object { if ($_.Name -match '^sprint-(\d+)-plan\.md$') { [int]$Matches[1] } }
    if ($nums) { $next = ($nums | Measure-Object -Maximum).Maximum + 1 }
}

$Sprint   = [int](Resolve-Auto -Key 'SP_SPRINT_NUMBER' -Default "$next")
$Goal     = Resolve-Auto -Key 'SP_GOAL'       -Default ''
$Velocity = Resolve-Auto -Key 'SP_VELOCITY'   -Default ''
$Capacity = Resolve-Auto -Key 'SP_CAPACITY'   -Default $Velocity
$Start    = Resolve-Auto -Key 'SP_START_DATE' -Default (Get-Date -Format 'yyyy-MM-dd')
$EndDef   = (Get-Date $Start).AddDays(14).ToString('yyyy-MM-dd')
$EndDate  = Resolve-Auto -Key 'SP_END_DATE'   -Default $EndDef

$Out = Join-Path $Dir ("sprint-{0:D2}-plan.md" -f $Sprint)

if ($env:KISS_DRY_RUN -eq '1') {
    Write-Host ("[dry-run] would write: {0}" -f $Out)
    exit 0
}

if (-not (Confirm-BeforeWrite -Message "Scaffold sprint plan at $Out.")) { Write-Error 'Aborted.'; exit 1 }

New-Item -ItemType Directory -Force -Path $Dir | Out-Null
if (Test-Path -LiteralPath $Out) { Write-Error "Sprint plan exists: $Out"; exit 2 }

$prev = $Sprint - 1
$tpl = Join-Path $SkillDir 'templates\sprint-plan-template.md'
$c = Get-Content -LiteralPath $tpl -Raw
$c = $c.Replace('{sprint_number}', "$Sprint").Replace('{prev_sprint}', "$prev")
$c = $c.Replace('{goal}', $(if ($Goal) { $Goal } else { '<TBD>' }))
$c = $c.Replace('{velocity}', $(if ($Velocity) { $Velocity } else { '<TBD>' }))
$c = $c.Replace('{capacity}', $(if ($Capacity) { $Capacity } else { '<TBD>' }))
$c = $c.Replace('{start_date}', $Start).Replace('{end_date}', $EndDate)
Set-Content -LiteralPath $Out -Value $c

Write-Extract -ArtefactPath $Out "SPRINT=$Sprint" "GOAL=$Goal" "VELOCITY=$Velocity" "CAPACITY=$Capacity" "START=$Start" "END=$EndDate" | Out-Null
Write-Host ("Wrote {0}" -f $Out)

if (-not $Goal)     { Append-Debt -File $Debts -Prefix 'SMDEBT' -Body "Sprint $Sprint has no goal (Priority: 🔴 Blocking)" | Out-Null }
if (-not $Velocity) { Append-Debt -File $Debts -Prefix 'SMDEBT' -Body "Sprint $Sprint has no velocity figure" | Out-Null }
