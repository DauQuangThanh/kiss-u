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
    @'
Usage: log-standup.ps1 [-Auto] [-Answers FILE] [-DryRun] [-Help] [-Notes FILE]

Appends today's standup log to docs/agile/standups/YYYY-MM-DD.md.
Notes source: -Notes FILE, stdin (piped), or STANDUP_NOTES env var.
Answer keys: STANDUP_DATE, STANDUP_SPRINT, STANDUP_NOTES.
'@ | Write-Host
    exit 0
}

$ctx = Read-Context
$SkillDir = (Resolve-Path -LiteralPath (Join-Path $ScriptDir '..\..')).Path
$Dir      = Join-Path (Join-Path $ctx.REPO_ROOT $ctx.DOCS_DIR) 'agile\standups'
$Debts    = Join-Path (Join-Path $ctx.REPO_ROOT $ctx.DOCS_DIR) 'agile\agile-debts.md'

$Date   = Resolve-Auto -Key 'STANDUP_DATE'   -Default (Get-Date -Format 'yyyy-MM-dd')
$Sprint = Resolve-Auto -Key 'STANDUP_SPRINT' -Default ''

if (-not $Sprint) {
    $plansDir = Join-Path (Join-Path $ctx.REPO_ROOT $ctx.DOCS_DIR) 'agile'
    if (Test-Path -LiteralPath $plansDir) {
        $nums = Get-ChildItem -LiteralPath $plansDir -Filter 'sprint-*-plan.md' -ErrorAction SilentlyContinue |
            ForEach-Object { if ($_.Name -match '^sprint-(\d+)-plan\.md$') { [int]$Matches[1] } }
        if ($nums) { $Sprint = "{0:D2}" -f ($nums | Measure-Object -Maximum).Maximum }
    }
    if (-not $Sprint) { $Sprint = 'unknown' }
}

# Notes sourcing
$notesText = ''
if ($Notes -and (Test-Path -LiteralPath $Notes)) {
    $notesText = Get-Content -LiteralPath $Notes -Raw
} elseif ($env:STANDUP_NOTES) {
    $notesText = $env:STANDUP_NOTES
} elseif (-not [Console]::IsInputRedirected -eq $false) {
    # stdin
    $notesText = [Console]::In.ReadToEnd()
}

$Out = Join-Path $Dir ("{0}.md" -f $Date)

if ($env:KISS_DRY_RUN -eq '1') {
    Write-Host ("[dry-run] would write: {0}" -f $Out)
    Write-Host ("[dry-run] sprint: {0}" -f $Sprint)
    Write-Host ("[dry-run] notes bytes: {0}" -f $notesText.Length)
    exit 0
}

if (-not $notesText) {
    Append-Debt -File $Debts -Prefix 'SMDEBT' -Body "Standup $Date requested with no notes — nothing logged" | Out-Null
    Write-Error "No standup notes provided (via -Notes FILE, stdin, or STANDUP_NOTES)."
    exit 3
}

if (-not (Confirm-BeforeWrite -Message "Log standup at $Out.")) { Write-Error 'Aborted.'; exit 1 }

New-Item -ItemType Directory -Force -Path $Dir | Out-Null
if (Test-Path -LiteralPath $Out) { Write-Error "Standup for $Date already logged: $Out"; exit 2 }

$tpl = Join-Path $SkillDir 'templates\standup-template.md'
$c = Get-Content -LiteralPath $tpl -Raw
$c = $c.Replace('{date}', $Date).Replace('{sprint}', $Sprint)
Set-Content -LiteralPath $Out -Value $c

$raw = @"

<!-- raw-notes-begin -->
``````text
$notesText
``````
<!-- raw-notes-end -->
"@
Add-Content -LiteralPath $Out -Value $raw
Write-Host ("Logged {0}" -f $Out)
