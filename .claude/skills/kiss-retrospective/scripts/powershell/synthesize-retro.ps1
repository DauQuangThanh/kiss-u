#!/usr/bin/env pwsh
param(
    [switch]$Auto, [switch]$DryRun, [string]$Answers, [switch]$Help,
    [string]$Notes
)
$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $PSCommandPath
. (Join-Path $ScriptDir 'common.ps1')

if ($Auto)    { $env:KISS_AUTO = '1' }
if ($DryRun)  { $env:KISS_DRY_RUN = '1' }
if ($Answers) { $env:KISS_ANSWERS = $Answers; Import-KissAnswers -Path $Answers }

if ($Help) {
    "Usage: synthesize-retro.ps1 [-Auto] [-Answers FILE] [-DryRun] [-Help] [-Notes FILE]`nAnswer keys: RETRO_SPRINT, RETRO_FORMAT, RETRO_NOTES." | Write-Host
    exit 0
}

$ctx = Read-Context
$SkillDir = (Resolve-Path -LiteralPath (Join-Path $ScriptDir '..\..')).Path
$Dir      = Join-Path (Join-Path $ctx.REPO_ROOT $ctx.DOCS_DIR) 'agile'
$Debts    = Join-Path $Dir 'agile-debts.md'

$Sprint = Resolve-Auto -Key 'RETRO_SPRINT' -Default ''
$Format = Resolve-Auto -Key 'RETRO_FORMAT' -Default 'wwwdt'

if (-not $Sprint) {
    if (Test-Path -LiteralPath $Dir) {
        $nums = Get-ChildItem -LiteralPath $Dir -Filter 'sprint-*-plan.md' -ErrorAction SilentlyContinue |
            ForEach-Object { if ($_.Name -match '^sprint-(\d+)-plan\.md$') { [int]$Matches[1] } }
        if ($nums) { $Sprint = "$( ($nums | Measure-Object -Maximum).Maximum )" }
    }
    if (-not $Sprint) { Write-Error "Cannot infer sprint — set RETRO_SPRINT=N"; exit 2 }
}

$notesText = ''
if ($Notes -and (Test-Path -LiteralPath $Notes)) {
    $notesText = Get-Content -LiteralPath $Notes -Raw
} elseif ($env:RETRO_NOTES) {
    $notesText = $env:RETRO_NOTES
} elseif ([Console]::IsInputRedirected) {
    $notesText = [Console]::In.ReadToEnd()
}

$Out = Join-Path $Dir ("retro-sprint-{0:D2}.md" -f [int]$Sprint)

if ($env:KISS_DRY_RUN -eq '1') {
    Write-Host ("[dry-run] would write: {0}" -f $Out)
    Write-Host ("[dry-run] sprint={0} format={1}" -f $Sprint, $Format)
    exit 0
}

if (-not $notesText) {
    Append-Debt -File $Debts -Prefix 'SMDEBT' -Body "Retro for sprint $Sprint requested with no notes" | Out-Null
    Write-Error "No retro notes provided."
    exit 3
}

if (-not (Confirm-BeforeWrite -Message "Scaffold retro at $Out.")) { Write-Error 'Aborted.'; exit 1 }

New-Item -ItemType Directory -Force -Path $Dir | Out-Null
if (Test-Path -LiteralPath $Out) { Write-Error "Retro already exists: $Out"; exit 2 }

$tpl = Join-Path $SkillDir 'templates\retro-template.md'
$c = Get-Content -LiteralPath $tpl -Raw
$c = $c.Replace('{sprint}', "$Sprint").Replace('{date}', (Get-Date -Format 'yyyy-MM-dd')).Replace('{format}', $Format)
Set-Content -LiteralPath $Out -Value $c

$raw = @"

<!-- raw-notes-begin -->
``````text
$notesText
``````
<!-- raw-notes-end -->
"@
Add-Content -LiteralPath $Out -Value $raw

Write-Extract -ArtefactPath $Out "SPRINT=$Sprint" "FORMAT=$Format" | Out-Null
Write-Host ("Wrote {0}" -f $Out)
