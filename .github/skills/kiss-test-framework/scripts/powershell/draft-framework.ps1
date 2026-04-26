#!/usr/bin/env pwsh
param([switch]$Auto, [switch]$DryRun, [string]$Answers, [switch]$Help)
$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $PSCommandPath
. (Join-Path $ScriptDir 'common.ps1')
if ($Auto)    { $env:KISS_AUTO = '1' }
if ($DryRun)  { $env:KISS_DRY_RUN = '1' }
if ($Answers) { $env:KISS_ANSWERS = $Answers; Import-KissAnswers -Path $Answers }
if ($Help) { "Usage: draft-framework.ps1 -Auto. Keys: TF_UNIT_FRAMEWORK, TF_INTEGRATION_FRAMEWORK, TF_E2E_FRAMEWORK." | Write-Host; exit 0 }
$ctx = Read-Context
if (-not $ctx.CURRENT_FEATURE) { Write-Error "current.feature required"; exit 2 }
$SkillDir = (Resolve-Path -LiteralPath (Join-Path $ScriptDir '..\..')).Path
$Dir = Get-FeatureScopedDir -Name 'testing'
$Out = Join-Path $Dir 'framework.md'

$detect = ''
$root = $ctx.REPO_ROOT
if (Test-Path (Join-Path $root 'pyproject.toml')) { $detect = 'pytest' }
elseif (Test-Path (Join-Path $root 'package.json')) {
    $pkg = Get-Content -LiteralPath (Join-Path $root 'package.json') -Raw
    if ($pkg -match '"vitest"') { $detect = 'vitest' }
    elseif ($pkg -match '"jest"') { $detect = 'jest' }
    elseif ($pkg -match '"mocha"') { $detect = 'mocha' }
    else { $detect = 'vitest' }
}
elseif (Test-Path (Join-Path $root 'go.mod'))    { $detect = 'go-test' }
elseif (Test-Path (Join-Path $root 'Cargo.toml')){ $detect = 'cargo-test' }
elseif (Test-Path (Join-Path $root 'pom.xml'))   { $detect = 'junit5' }

$Unit   = Resolve-Auto -Key 'TF_UNIT_FRAMEWORK'        -Default $(if ($detect) { $detect } else { 'pytest' })
$Integ  = Resolve-Auto -Key 'TF_INTEGRATION_FRAMEWORK' -Default $Unit
$E2e    = Resolve-Auto -Key 'TF_E2E_FRAMEWORK'         -Default 'playwright'

if ($env:KISS_DRY_RUN -eq '1') { Write-Host ("[dry-run] unit={0} integ={1} e2e={2}" -f $Unit, $Integ, $E2e); exit 0 }
if (Test-Path -LiteralPath $Out) { Write-Error "Framework doc exists: $Out"; exit 2 }
if (-not (Confirm-BeforeWrite -Message "Scaffold framework doc at $Out.")) { Write-Error 'Aborted.'; exit 1 }

$tpl = Join-Path $SkillDir 'templates\framework-template.md'
$c = Get-Content -LiteralPath $tpl -Raw
$c = $c.Replace('{feature}', $ctx.CURRENT_FEATURE).Replace('{date}', (Get-Date -Format 'yyyy-MM-dd'))
$c = $c.Replace('{unit}', $Unit).Replace('{integration}', $Integ).Replace('{e2e}', $E2e)
Set-Content -LiteralPath $Out -Value $c
Write-Extract -ArtefactPath $Out "UNIT=$Unit" "INTEGRATION=$Integ" "E2E=$E2e" | Out-Null
Write-Host ("Wrote {0}" -f $Out)
