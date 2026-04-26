#!/usr/bin/env pwsh
param([switch]$Auto, [switch]$DryRun, [string]$Answers, [switch]$Help)
$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $PSCommandPath
. (Join-Path $ScriptDir 'common.ps1')
if ($Auto)    { $env:KISS_AUTO = '1' }
if ($DryRun)  { $env:KISS_DRY_RUN = '1' }
if ($Answers) { $env:KISS_ANSWERS = $Answers; Import-KissAnswers -Path $Answers }
if ($Help) { "Usage: scaffold-regression.ps1 -Auto. Keys: RT_BUG_ID, RT_LEVEL." | Write-Host; exit 0 }
$ctx = Read-Context
$SkillDir = (Resolve-Path -LiteralPath (Join-Path $ScriptDir '..\..')).Path
$Dir = Join-Path (Join-Path $ctx.REPO_ROOT $ctx.DOCS_DIR) 'testing'
$Out = Join-Path $Dir 'regression-index.md'
$Debts = Join-Path $Dir 'test-debts.md'

$Bug   = Resolve-Auto -Key 'RT_BUG_ID' -Default ''
$Level = Resolve-Auto -Key 'RT_LEVEL'  -Default 'integration'
if (-not $Bug) { Write-Error "RT_BUG_ID required"; exit 2 }

if ($env:KISS_DRY_RUN -eq '1') { Write-Host ("[dry-run] would update: {0}  (bug={1} level={2})" -f $Out, $Bug, $Level); exit 0 }
if (-not (Confirm-BeforeWrite -Message "Update regression index at $Out.")) { Write-Error 'Aborted.'; exit 1 }
New-Item -ItemType Directory -Force -Path $Dir | Out-Null

if (-not (Test-Path -LiteralPath $Out)) {
    $tpl = Join-Path $SkillDir 'templates\regression-index-template.md'
    $c = Get-Content -LiteralPath $tpl -Raw
    $c = $c.Replace('{date}', (Get-Date -Format 'yyyy-MM-dd'))
    # strip placeholder row
    $lines = ($c -split "`n") | Where-Object { $_ -notmatch '^\| BUG-NN \|' }
    Set-Content -LiteralPath $Out -Value ($lines -join "`n")
}

$content = Get-Content -LiteralPath $Out -Raw
if ($content -notmatch ("^\| " + [regex]::Escape($Bug) + " \|")) {
    $row = "| $Bug | Open | $Level | <tests/regression/...> | agent to fill path + notes |"
    Add-Content -LiteralPath $Out -Value $row
    Write-Host ("Added {0} row to {1}" -f $Bug, $Out)
} else {
    Write-Host ("{0} already present in {1}" -f $Bug, $Out)
}

Append-Debt -File $Debts -Prefix 'TQDEBT' -Body "Regression test scaffolded for $Bug — agent must write the actual test file" | Out-Null
