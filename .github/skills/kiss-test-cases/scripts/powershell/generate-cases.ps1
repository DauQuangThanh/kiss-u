#!/usr/bin/env pwsh
param([switch]$Auto, [switch]$DryRun, [string]$Answers, [switch]$Help)
$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $PSCommandPath
. (Join-Path $ScriptDir 'common.ps1')
if ($Auto)    { $env:KISS_AUTO = '1' }
if ($DryRun)  { $env:KISS_DRY_RUN = '1' }
if ($Answers) { $env:KISS_ANSWERS = $Answers; Import-KissAnswers -Path $Answers }
if ($Help) { "Usage: generate-cases.ps1 -Auto. Keys: TC_CASES_PER_AC, TC_INCLUDE_BOUNDARY." | Write-Host; exit 0 }
$ctx = Read-Context
if (-not $ctx.CURRENT_FEATURE) { Write-Error "current.feature required"; exit 2 }
$SkillDir = (Resolve-Path -LiteralPath (Join-Path $ScriptDir '..\..')).Path
$Dir = Get-FeatureScopedDir -Name 'testing'
$Out = Join-Path $Dir 'test-cases.md'
if (Test-Path -LiteralPath $Out) { Write-Error "Test cases exist: $Out"; exit 2 }
if ($env:KISS_DRY_RUN -eq '1') { Write-Host ("[dry-run] would write: {0}" -f $Out); exit 0 }
if (-not (Confirm-BeforeWrite -Message "Scaffold test cases at $Out.")) { Write-Error 'Aborted.'; exit 1 }
$tpl = Join-Path $SkillDir 'templates\test-cases-template.md'
$c = Get-Content -LiteralPath $tpl -Raw
$c = $c.Replace('{feature}', $ctx.CURRENT_FEATURE).Replace('{date}', (Get-Date -Format 'yyyy-MM-dd'))
Set-Content -LiteralPath $Out -Value $c
Write-Extract -ArtefactPath $Out "FEATURE=$($ctx.CURRENT_FEATURE)" | Out-Null
Write-Host ("Wrote {0}" -f $Out)
