#!/usr/bin/env pwsh
param([switch]$Auto, [switch]$DryRun, [string]$Answers, [switch]$Help)
$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $PSCommandPath
. (Join-Path $ScriptDir 'common.ps1')
if ($Auto)    { $env:KISS_AUTO = '1' }
if ($DryRun)  { $env:KISS_DRY_RUN = '1' }
if ($Answers) { $env:KISS_ANSWERS = $Answers; Import-KissAnswers -Path $Answers }
if ($Help) { "Usage: draft-strategy.ps1 -Auto. Keys: TS_RISK_TIERS, TS_LEVELS, TS_ENVIRONMENTS, TS_COVERAGE_TARGET." | Write-Host; exit 0 }

$ctx = Read-Context
if (-not $ctx.CURRENT_FEATURE) { Write-Error "current.feature required"; exit 2 }
$SkillDir = (Resolve-Path -LiteralPath (Join-Path $ScriptDir '..\..')).Path
$Dir = Get-FeatureScopedDir -Name 'testing'
$Out = Join-Path $Dir 'strategy.md'

$Tiers  = Resolve-Auto -Key 'TS_RISK_TIERS'       -Default 'high,medium,low'
$Levels = Resolve-Auto -Key 'TS_LEVELS'           -Default 'unit,integration,e2e'
$Envs   = Resolve-Auto -Key 'TS_ENVIRONMENTS'     -Default 'dev,staging,prod'
$Cov    = Resolve-Auto -Key 'TS_COVERAGE_TARGET'  -Default '80'

if ($env:KISS_DRY_RUN -eq '1') { Write-Host ("[dry-run] would write: {0}" -f $Out); exit 0 }
if (Test-Path -LiteralPath $Out) { Write-Error "Strategy exists: $Out"; exit 2 }
if (-not (Confirm-BeforeWrite -Message "Scaffold test strategy at $Out.")) { Write-Error 'Aborted.'; exit 1 }

$tpl = Join-Path $SkillDir 'templates\strategy-template.md'
$c = Get-Content -LiteralPath $tpl -Raw
$c = $c.Replace('{feature}', $ctx.CURRENT_FEATURE).Replace('{date}', (Get-Date -Format 'yyyy-MM-dd'))
$c = $c.Replace('{risk_tiers}', $Tiers).Replace('{environments}', $Envs).Replace('{coverage_target}', $Cov)
Set-Content -LiteralPath $Out -Value $c

Write-Extract -ArtefactPath $Out "FEATURE=$($ctx.CURRENT_FEATURE)" "LEVELS=$Levels" "RISK_TIERS=$Tiers" "ENVIRONMENTS=$Envs" "COVERAGE_TARGET=$Cov" | Out-Null
Write-Host ("Wrote {0}" -f $Out)
