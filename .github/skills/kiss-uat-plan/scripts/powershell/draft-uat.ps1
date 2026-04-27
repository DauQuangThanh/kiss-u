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
Usage: draft-uat.ps1 [-Auto] [-Answers FILE] [-DryRun] [-Help]

Drafts the UAT plan and sign-off ledger for a feature.

Answer keys: UAT_FEATURE, UAT_ENV, UAT_START_DATE, UAT_END_DATE,
             UAT_CRITICAL_THRESHOLD, UAT_HIGH_THRESHOLD.
'@ | Write-Host; exit 0
}

$ctx      = Read-Context
$SkillDir = (Resolve-Path -LiteralPath (Join-Path $ScriptDir '../..')).Path
$Date     = Get-Date -Format 'yyyy-MM-dd'

$Feature       = Resolve-Auto -Key 'UAT_FEATURE'            -Default ($ctx.CURRENT_FEATURE ?? '')
$UatEnv        = Resolve-Auto -Key 'UAT_ENV'                -Default 'staging'
$StartDate     = Resolve-Auto -Key 'UAT_START_DATE'         -Default ''
$EndDate       = Resolve-Auto -Key 'UAT_END_DATE'           -Default ''
$HighThreshold = Resolve-Auto -Key 'UAT_HIGH_THRESHOLD'     -Default '3'

if ([string]::IsNullOrEmpty($Feature)) {
    Write-Error "UAT_FEATURE is required (or set current.feature in .kiss/context.yml)."
    exit 2
}

$TestDir    = Get-WorktypeDir -Name 'testing'
$FeatureDir = Join-Path $TestDir $Feature
New-Item -ItemType Directory -Force -Path $FeatureDir | Out-Null

$Out    = Join-Path $FeatureDir 'uat-plan.md'
$SignOff = Join-Path $FeatureDir 'uat-sign-off.md'
$Debts  = Join-Path $FeatureDir 'uat-debts.md'

if ($env:KISS_DRY_RUN -eq '1') {
    Write-Host ("[dry-run] would write: {0}" -f $Out)
    Write-Host ("  feature={0}  env={1}  start={2}  end={3}" -f $Feature, $UatEnv, $StartDate, $EndDate)
    exit 0
}

if (-not (Confirm-BeforeWrite -Message "Write UAT plan to $Out.")) {
    Write-Error 'Aborted.'; exit 1
}

$sdDisplay = if ($StartDate) { $StartDate } else { 'TBD' }
$edDisplay = if ($EndDate) { $EndDate } else { 'TBD' }

$tplPlan = Get-Content -LiteralPath (Join-Path $SkillDir 'templates\uat-plan-template.md') -Raw
$tplPlan = $tplPlan.Replace('{feature}', $Feature).Replace('{revision}', '1.0').Replace('{date}', $Date)
$tplPlan = $tplPlan.Replace('{uat_env}', $UatEnv).Replace('{start_date}', $sdDisplay).Replace('{end_date}', $edDisplay)
$tplPlan = $tplPlan.Replace('{high_threshold}', $HighThreshold)
$tplPlan = $tplPlan.Replace('{scenarios}', '<!-- AI: populate UAT scenarios from spec.md user stories -->')
$tplPlan = $tplPlan.Replace('{in_scope}', '<!-- AI: populate from spec.md scope -->')
$tplPlan = $tplPlan.Replace('{out_scope}', '<!-- AI: populate from spec.md out-of-scope -->')
$tplPlan = $tplPlan.Replace('{test_data_policy}', 'Representative synthetic data')
$tplPlan = $tplPlan.Replace('{data_refresh}', 'Before each UAT session')
$tplPlan = $tplPlan.Replace('{user_rep_count}', '3–5').Replace('{sme_count}', '1–2')
Set-Content -LiteralPath $Out -Value $tplPlan

$tplSO = Get-Content -LiteralPath (Join-Path $SkillDir 'templates\uat-sign-off-template.md') -Raw
$tplSO = $tplSO.Replace('{feature}', $Feature).Replace('{date}', $Date)
$tplSO = $tplSO.Replace('{start_date}', $sdDisplay).Replace('{end_date}', $edDisplay)
foreach ($n in @('total_scenarios','passed','failed','not_run','open_critical','open_high')) {
    $tplSO = $tplSO.Replace("{$n}", '0')
}
Set-Content -LiteralPath $SignOff -Value $tplSO

Write-Extract -ArtefactPath $Out `
    "UAT_REVISION=1.0" `
    "UAT_FEATURE=$Feature" `
    "UAT_ENV=$UatEnv" `
    "UAT_START_DATE=$sdDisplay" `
    "UAT_END_DATE=$edDisplay" `
    "UAT_HIGH_THRESHOLD=$HighThreshold" | Out-Null

Write-Host ("Wrote {0}" -f $Out)
Write-Host ("Wrote {0}" -f $SignOff)
