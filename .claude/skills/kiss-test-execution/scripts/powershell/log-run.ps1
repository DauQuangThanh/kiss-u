#!/usr/bin/env pwsh
param([switch]$Auto, [switch]$DryRun, [string]$Answers, [switch]$Help)
$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $PSCommandPath
. (Join-Path $ScriptDir 'common.ps1')
if ($Auto)    { $env:KISS_AUTO = '1' }
if ($DryRun)  { $env:KISS_DRY_RUN = '1' }
if ($Answers) { $env:KISS_ANSWERS = $Answers; Import-KissAnswers -Path $Answers }
if ($Help) { "Usage: log-run.ps1 -Auto. Keys: TE_RUN_DATE, TE_PASSED, TE_FAILED, TE_SKIPPED, TE_FAILED_TC_IDS, TE_NOTES." | Write-Host; exit 0 }
$ctx = Read-Context
if (-not $ctx.CURRENT_FEATURE) { Write-Error "current.feature required"; exit 2 }
$SkillDir = (Resolve-Path -LiteralPath (Join-Path $ScriptDir '..\..')).Path
$Dir = Get-FeatureScopedDir -Name 'testing'
$Out = Join-Path $Dir 'execution.md'
$Debts = Join-Path $Dir 'test-debts.md'

$DateV     = Resolve-Auto -Key 'TE_RUN_DATE'       -Default (Get-Date -Format 'yyyy-MM-dd')
$Passed    = Resolve-Auto -Key 'TE_PASSED'         -Default ''
$Failed    = Resolve-Auto -Key 'TE_FAILED'         -Default '0'
$Skipped   = Resolve-Auto -Key 'TE_SKIPPED'        -Default '0'
$FailedIds = Resolve-Auto -Key 'TE_FAILED_TC_IDS'  -Default ''
$Notes     = Resolve-Auto -Key 'TE_NOTES'          -Default ''
if (-not $Passed) { Write-Error "TE_PASSED required"; exit 2 }

if ($env:KISS_DRY_RUN -eq '1') { Write-Host ("[dry-run] would append run $DateV"); exit 0 }
if (-not (Confirm-BeforeWrite -Message "Append execution run to $Out.")) { Write-Error 'Aborted.'; exit 1 }

if (-not (Test-Path -LiteralPath $Out)) {
    $tpl = Join-Path $SkillDir 'templates\execution-template.md'
    $c = Get-Content -LiteralPath $tpl -Raw
    $c = $c.Replace('{feature}', $ctx.CURRENT_FEATURE).Replace('{date}', (Get-Date -Format 'yyyy-MM-dd'))
    $c = $c.Replace('{run_date}', '').Replace('{passed}', '').Replace('{failed}', '').Replace('{skipped}', '').Replace('{notes}', '').Replace('{failed_ids}', '')
    $lines = $c -split "`n"
    $out = @(); $skip = $false
    foreach ($l in $lines) {
        if ($l -match '^### Run ') { $skip = $true; continue }
        if ($skip -and $l -match '^---$') { $skip = $false; continue }
        if (-not $skip) { $out += $l }
    }
    Set-Content -LiteralPath $Out -Value ($out -join "`n")
}

$block = @"

### Run $DateV

- **Passed:** $Passed
- **Failed:** $Failed
- **Skipped:** $Skipped
- **Notes:** $(if ($Notes) { $Notes } else { '<none>' })
- **Failed TC ids:** $(if ($FailedIds) { $FailedIds } else { '<none>' })
"@

if ($FailedIds) {
    $rows = @()
    foreach ($id in ($FailedIds -split ',')) {
        $rows += "| $($id.Trim()) | BUG-TBD | Open |"
    }
    $block += @"

#### Links to bug reports

| Failed TC | Bug id | Status |
|---|---|---|
$($rows -join "`n")
"@
}

$block += "`n`n---"
Add-Content -LiteralPath $Out -Value $block

$total = [int]$Passed + [int]$Failed + [int]$Skipped
Write-Extract -ArtefactPath $Out "LAST_RUN=$DateV" "TOTAL=$total" "PASSED=$Passed" "FAILED=$Failed" "SKIPPED=$Skipped" | Out-Null
Write-Host ("Appended run {0} to {1}" -f $DateV, $Out)

if ($Failed -ne '0') {
    Append-Debt -File $Debts -Prefix 'TQDEBT' -Body "Run $DateV had $Failed failed TC(s): $(if ($FailedIds) { $FailedIds } else { '<unnamed>' })" | Out-Null
}
