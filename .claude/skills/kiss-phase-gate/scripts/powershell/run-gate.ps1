#!/usr/bin/env pwsh
param([switch]$Auto, [switch]$DryRun, [string]$Answers, [switch]$Help)
$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $PSCommandPath
. (Join-Path $ScriptDir 'common.ps1')
if ($Auto)    { $env:KISS_AUTO = '1' }
if ($DryRun)  { $env:KISS_DRY_RUN = '1' }
if ($Answers) { $env:KISS_ANSWERS = $Answers; Import-KissAnswers -Path $Answers }
if ($Help) {
    @'
Usage: run-gate.ps1 [-Auto] [-Answers FILE] [-DryRun] [-Help]

Creates a phase-gate record at docs/project/gates/GATE-<type>-<date>.md.

Answer keys: GATE_TYPE, GATE_DATE, GATE_COVERAGE_THRESHOLD.
Valid gate types: requirements | architecture | ttr | orr | go-live
'@ | Write-Host; exit 0
}

$ctx       = Read-Context
$SkillDir  = (Resolve-Path -LiteralPath (Join-Path $ScriptDir '../..')).Path
$GatesDir  = Join-Path (Join-Path (Join-Path $ctx.REPO_ROOT $ctx.DOCS_DIR) 'project') 'gates'
$Debts     = Join-Path $GatesDir 'gate-debts.md'

$GateType  = Resolve-Auto -Key 'GATE_TYPE'               -Default ''
$GateDate  = Resolve-Auto -Key 'GATE_DATE'               -Default (Get-Date -Format 'yyyy-MM-dd')
$Threshold = Resolve-Auto -Key 'GATE_COVERAGE_THRESHOLD' -Default '80'

$validTypes = @('requirements','architecture','ttr','orr','go-live')
if ([string]::IsNullOrEmpty($GateType)) {
    Write-Error "GATE_TYPE is required. Valid values: $($validTypes -join ' | ')"
    exit 2
}
if ($GateType -notin $validTypes) {
    Write-Error "Unknown GATE_TYPE '$GateType'. Valid: $($validTypes -join ' | ')"
    exit 2
}

$gateLabels = @{
    'requirements' = 'System Requirements Review (SRR)'
    'architecture' = 'Critical Design Review (CDR)'
    'ttr'          = 'Test Readiness Review (TRR)'
    'orr'          = 'Operational Readiness Review (ORR)'
    'go-live'      = 'Go/No-Go Review'
}
$GateLabel = $gateLabels[$GateType]
$Out       = Join-Path $GatesDir ("GATE-{0}-{1}.md" -f $GateType, $GateDate)

if ($env:KISS_DRY_RUN -eq '1') {
    Write-Host ("[dry-run] would write: {0}" -f $Out)
    Write-Host ("  gate_type={0}  date={1}  threshold={2}%" -f $GateType, $GateDate, $Threshold)
    exit 0
}

if (-not (Confirm-BeforeWrite -Message "Write gate record to $Out.")) {
    Write-Error 'Aborted.'; exit 1
}

New-Item -ItemType Directory -Force -Path $GatesDir | Out-Null
$Project = Split-Path $ctx.REPO_ROOT -Leaf
$tpl = Get-Content -LiteralPath (Join-Path $SkillDir 'templates\gate-template.md') -Raw
$tpl = $tpl.Replace('{gate_label}', $GateLabel).Replace('{gate_type}', $GateType)
$tpl = $tpl.Replace('{project}', $Project).Replace('{date}', $GateDate)
$tpl = $tpl.Replace('{deliverables}',         '<!-- AI: populate from upstream artefact scan -->')
$tpl = $tpl.Replace('{entry_criteria}',       "<!-- AI: populate for $GateType gate -->")
$tpl = $tpl.Replace('{exit_criteria}',        "<!-- AI: populate for $GateType gate -->")
$tpl = $tpl.Replace('{risks}',                '<!-- AI: populate from risk-register.md -->')
$tpl = $tpl.Replace('{blockers}',             '<!-- AI: populate from gate-debts.md -->')
$tpl = $tpl.Replace('{waivers}',              '<!-- None documented yet -->')
$tpl = $tpl.Replace('{recommendation}',       'Pending review')
$tpl = $tpl.Replace('{recommendation_detail}','<!-- AI: add recommendation after criteria evaluation -->')
Set-Content -LiteralPath $Out -Value $tpl

Write-Extract -ArtefactPath $Out `
    "GATE_TYPE=$GateType" `
    "GATE_LABEL=$GateLabel" `
    "GATE_DATE=$GateDate" `
    "GATE_OUTCOME=Pending" `
    "OPEN_BLOCKERS=0" `
    "COVERAGE_THRESHOLD=$Threshold" | Out-Null

Write-Host ("Wrote {0}" -f $Out)
Write-Host "Next: AI evaluates criteria and populates the gate record, then stakeholders sign off"
