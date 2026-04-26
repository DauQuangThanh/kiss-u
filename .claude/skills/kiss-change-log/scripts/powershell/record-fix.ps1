#!/usr/bin/env pwsh
param([switch]$Auto, [switch]$DryRun, [string]$Answers, [switch]$Help)
$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $PSCommandPath
. (Join-Path $ScriptDir 'common.ps1')
if ($Auto)    { $env:KISS_AUTO = '1' }
if ($DryRun)  { $env:KISS_DRY_RUN = '1' }
if ($Answers) { $env:KISS_ANSWERS = $Answers; Import-KissAnswers -Path $Answers }
if ($Help) { "Usage: record-fix.ps1 -Auto. Keys: CR_BUG_ID, CR_COMMIT, CR_PR, CR_FILES, CR_REGRESSION_TEST, CR_REVIEWER." | Write-Host; exit 0 }
$ctx = Read-Context
$SkillDir = (Resolve-Path -LiteralPath (Join-Path $ScriptDir '..\..')).Path
$Dir = Join-Path (Join-Path $ctx.REPO_ROOT $ctx.DOCS_DIR) 'bugs'
$Reg = Join-Path $Dir 'change-register.md'
$Debts = Join-Path $Dir 'fix-debts.md'

$Bug      = Resolve-Auto -Key 'CR_BUG_ID'           -Default ''
$Commit   = Resolve-Auto -Key 'CR_COMMIT'           -Default ''
$Pr       = Resolve-Auto -Key 'CR_PR'               -Default ''
$Files    = Resolve-Auto -Key 'CR_FILES'            -Default ''
$Regr     = Resolve-Auto -Key 'CR_REGRESSION_TEST'  -Default ''
$Reviewer = Resolve-Auto -Key 'CR_REVIEWER'         -Default ''

foreach ($pair in @(@('BUG',$Bug),@('COMMIT',$Commit),@('REVIEWER',$Reviewer))) {
    if (-not $pair[1]) { Write-Error ("CR_{0} required" -f $pair[0]); exit 2 }
}

if ($env:KISS_DRY_RUN -eq '1') { Write-Host ("[dry-run] would append: bug={0} commit={1}" -f $Bug, $Commit); exit 0 }
if (-not (Confirm-BeforeWrite -Message "Append fix row to $Reg.")) { Write-Error 'Aborted.'; exit 1 }

New-Item -ItemType Directory -Force -Path $Dir | Out-Null
if (-not (Test-Path -LiteralPath $Reg)) {
    $tpl = Join-Path $SkillDir 'templates\change-register-template.md'
    $c = Get-Content -LiteralPath $tpl -Raw
    $c = $c.Replace('{date}', (Get-Date -Format 'yyyy-MM-dd'))
    $lines = ($c -split "`n") | Where-Object { $_ -notmatch '^\| BUG-NN \|' }
    Set-Content -LiteralPath $Reg -Value ($lines -join "`n")
}

$filesCell = if ($Files) { ($Files -replace ';', ', ') } else { '<none>' }
$row = '| {0} | {1} | `{2}` | {3} | {4} | {5} | {6} |' -f $Bug, (Get-Date -Format 'yyyy-MM-dd'), $Commit, $(if ($Pr) { $Pr } else { '<none>' }), $filesCell, $(if ($Regr) { $Regr } else { '<none>' }), $Reviewer
Add-Content -LiteralPath $Reg -Value $row

$text = Get-Content -LiteralPath $Reg -Raw
$total = ([regex]::Matches($text, '(?m)^\| BUG-')).Count
Write-Extract -ArtefactPath $Reg "TOTAL_FIXES=$total" "LAST_FIX=$Bug" "LAST_COMMIT=$Commit" | Out-Null
Write-Host ("Appended {0} to {1}" -f $Bug, $Reg)

if (-not $Regr) {
    Append-Debt -File $Debts -Prefix 'BFDEBT' -Body "Fix for $Bug has no regression test linked (commit $Commit)" | Out-Null
}
