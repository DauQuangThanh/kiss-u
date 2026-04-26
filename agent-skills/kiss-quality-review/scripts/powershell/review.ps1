#!/usr/bin/env pwsh
param([switch]$Auto, [switch]$DryRun, [string]$Answers, [switch]$Help)
$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $PSCommandPath
. (Join-Path $ScriptDir 'common.ps1')
if ($Auto)    { $env:KISS_AUTO = '1' }
if ($DryRun)  { $env:KISS_DRY_RUN = '1' }
if ($Answers) { $env:KISS_ANSWERS = $Answers; Import-KissAnswers -Path $Answers }
if ($Help) { "Usage: review.ps1 -Auto. Keys: QR_SCOPE, QR_MAX_CYCLOMATIC, QR_MAX_FUNCTION_LINES." | Write-Host; exit 0 }
$ctx = Read-Context
if (-not $ctx.CURRENT_FEATURE) { Write-Error "current.feature required"; exit 2 }
$SkillDir = (Resolve-Path -LiteralPath (Join-Path $ScriptDir '..\..')).Path
$Dir = Get-FeatureScopedDir -Name 'reviews'
$Out = Join-Path $Dir 'quality.md'
$Scope = Resolve-Auto -Key 'QR_SCOPE' -Default 'src/**'

if ($env:KISS_DRY_RUN -eq '1') { Write-Host ("[dry-run] would write: {0}" -f $Out); exit 0 }
if (Test-Path -LiteralPath $Out) { Write-Error "Review exists: $Out"; exit 2 }
if (-not (Confirm-BeforeWrite -Message "Scaffold quality review at $Out.")) { Write-Error 'Aborted.'; exit 1 }

$tpl = Join-Path $SkillDir 'templates\quality-review-template.md'
$c = Get-Content -LiteralPath $tpl -Raw
$c = $c.Replace('{feature}', $ctx.CURRENT_FEATURE).Replace('{date}', (Get-Date -Format 'yyyy-MM-dd')).Replace('{scope}', $Scope)
Set-Content -LiteralPath $Out -Value $c
Write-Extract -ArtefactPath $Out "FEATURE=$($ctx.CURRENT_FEATURE)" "SCOPE=$Scope" | Out-Null
Write-Host ("Wrote {0}" -f $Out)
