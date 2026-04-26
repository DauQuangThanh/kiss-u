#!/usr/bin/env pwsh
param([switch]$Auto, [switch]$DryRun, [string]$Answers, [switch]$Help)
$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $PSCommandPath
. (Join-Path $ScriptDir 'common.ps1')
if ($Auto)    { $env:KISS_AUTO = '1' }
if ($DryRun)  { $env:KISS_DRY_RUN = '1' }
if ($Answers) { $env:KISS_ANSWERS = $Answers; Import-KissAnswers -Path $Answers }
if ($Help) { "Usage: draft-gates.ps1 -Auto. Keys: QG_COVERAGE_PR, QG_COVERAGE_RELEASE, QG_P95_MS, QG_MAX_HIGH_VULN, QG_MAX_CRIT_VULN." | Write-Host; exit 0 }
$ctx = Read-Context
if (-not $ctx.CURRENT_FEATURE) { Write-Error "current.feature required"; exit 2 }
$SkillDir = (Resolve-Path -LiteralPath (Join-Path $ScriptDir '..\..')).Path
$Dir = Get-FeatureScopedDir -Name 'testing'
$Out = Join-Path $Dir 'quality-gates.md'

$CP  = Resolve-Auto -Key 'QG_COVERAGE_PR'       -Default '80'
$CR  = Resolve-Auto -Key 'QG_COVERAGE_RELEASE'  -Default '85'
$P95 = Resolve-Auto -Key 'QG_P95_MS'            -Default '200'
$MH  = Resolve-Auto -Key 'QG_MAX_HIGH_VULN'     -Default '0'
$MC  = Resolve-Auto -Key 'QG_MAX_CRIT_VULN'     -Default '0'

if ($env:KISS_DRY_RUN -eq '1') { Write-Host ("[dry-run] would write: {0}" -f $Out); exit 0 }
if (Test-Path -LiteralPath $Out) { Write-Error "Gates doc exists: $Out"; exit 2 }
if (-not (Confirm-BeforeWrite -Message "Scaffold gates at $Out.")) { Write-Error 'Aborted.'; exit 1 }

$tpl = Join-Path $SkillDir 'templates\gates-template.md'
$c = Get-Content -LiteralPath $tpl -Raw
$c = $c.Replace('{feature}', $ctx.CURRENT_FEATURE).Replace('{date}', (Get-Date -Format 'yyyy-MM-dd'))
$c = $c.Replace('{cov_pr}', $CP).Replace('{cov_release}', $CR).Replace('{p95_ms}', $P95).Replace('{max_high}', $MH).Replace('{max_crit}', $MC)
Set-Content -LiteralPath $Out -Value $c
Write-Extract -ArtefactPath $Out "COVERAGE_PR=$CP" "COVERAGE_RELEASE=$CR" "P95_MS=$P95" "MAX_HIGH_VULN=$MH" "MAX_CRIT_VULN=$MC" | Out-Null
Write-Host ("Wrote {0}" -f $Out)
