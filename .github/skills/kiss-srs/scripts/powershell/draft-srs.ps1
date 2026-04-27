#!/usr/bin/env pwsh
param(
    [switch]$Auto,
    [switch]$DryRun,
    [string]$Answers,
    [switch]$Help
)
$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $PSCommandPath
. (Join-Path $ScriptDir 'common.ps1')
if ($Auto)    { $env:KISS_AUTO = '1' }
if ($DryRun)  { $env:KISS_DRY_RUN = '1' }
if ($Answers) { $env:KISS_ANSWERS = $Answers; Import-KissAnswers -Path $Answers }
if ($Help) {
    @'
Usage: draft-srs.ps1 [-Auto] [-Answers FILE] [-DryRun] [-Help]

Aggregates all feature specs into a consolidated SRS document at
docs/analysis/srs.md. Numbers every FR and NFR.

Answer keys: SRS_TITLE, SRS_REVISION, SRS_AUDIENCE,
             SRS_INCLUDE_TRACE_STUB.
'@ | Write-Host; exit 0
}

$ctx = Read-Context
$SkillDir = (Resolve-Path -LiteralPath (Join-Path $ScriptDir '../..')).Path
$ArchDir  = Get-WorktypeDir -Name 'architecture'
$Out      = Join-Path $ArchDir 'srs.md'
$Debts    = Join-Path $ArchDir 'srs-debts.md'

$Project  = Resolve-Auto -Key 'SRS_PROJECT'            -Default (Split-Path $ctx.REPO_ROOT -Leaf)
$Title    = Resolve-Auto -Key 'SRS_TITLE'              -Default "$Project Software Requirements Specification"
$Revision = Resolve-Auto -Key 'SRS_REVISION'           -Default '1.0'
$Audience = Resolve-Auto -Key 'SRS_AUDIENCE'           -Default 'internal'
$IncTrace = Resolve-Auto -Key 'SRS_INCLUDE_TRACE_STUB' -Default 'true'

if ($Audience -notin @('internal','external','regulatory','all')) {
    $Audience = 'internal'
    Write-Decision -Kind 'default-applied' -What "SRS_AUDIENCE set to 'internal'" -Why 'invalid value provided' | Out-Null
}

# Discover spec files
$SpecsRoot  = Join-Path $ctx.REPO_ROOT $ctx.SPECS_DIR
$SpecCount  = 0
if (Test-Path -LiteralPath $SpecsRoot) {
    $SpecCount = (Get-ChildItem -LiteralPath $SpecsRoot -Recurse -Filter 'spec.md' -ErrorAction SilentlyContinue).Count
}
if ($SpecCount -eq 0) {
    Write-Error "No spec.md files found under $($ctx.SPECS_DIR). Run /kiss.specify for each feature first."
    exit 2
}

if ($env:KISS_DRY_RUN -eq '1') {
    Write-Host ("[dry-run] would write: {0}" -f $Out)
    Write-Host ("  title={0}  revision={1}  audience={2}" -f $Title, $Revision, $Audience)
    exit 0
}

if (-not (Confirm-BeforeWrite -Message "Write SRS to $Out (aggregating $SpecCount spec(s)).")) {
    Write-Error 'Aborted.'; exit 1
}

$tpl = Get-Content -LiteralPath (Join-Path $SkillDir 'templates\srs-template.md') -Raw
$date = Get-Date -Format 'yyyy-MM-dd'
$tpl = $tpl.Replace('{title}', $Title).Replace('{project}', $Project)
$tpl = $tpl.Replace('{revision}', $Revision).Replace('{date}', $date)
Set-Content -LiteralPath $Out -Value $tpl

Write-Extract -ArtefactPath $Out `
    "SRS_REVISION=$Revision" `
    "SRS_TITLE=$Title" `
    "SRS_AUDIENCE=$Audience" `
    "BASELINE_DATE=$date" `
    "SPEC_COUNT=$SpecCount" | Out-Null

Write-Host ("Wrote {0}" -f $Out)
Write-Host "Next: populate FR/NFR sections from spec files, then run /kiss.traceability-matrix"
