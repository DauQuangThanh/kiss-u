#!/usr/bin/env pwsh
param([switch]$Auto, [switch]$DryRun, [string]$Answers, [switch]$Help)
$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $PSCommandPath
. (Join-Path $ScriptDir 'common.ps1')
if ($Auto)    { $env:KISS_AUTO = '1' }
if ($DryRun)  { $env:KISS_DRY_RUN = '1' }
if ($Answers) { $env:KISS_ANSWERS = $Answers; Import-KissAnswers -Path $Answers }
if ($Help) { "Usage: draft-design.ps1 -Auto. Keys: DD_PATTERN, DD_API_STYLE, DD_DATA_STYLE, DD_INCLUDE_API_CONTRACT, DD_INCLUDE_DATA_MODEL." | Write-Host; exit 0 }

$ctx = Read-Context
if (-not $ctx.CURRENT_FEATURE) { Write-Error "current.feature required"; exit 2 }

$SkillDir = (Resolve-Path -LiteralPath (Join-Path $ScriptDir '..\..')).Path
$Dir   = Get-FeatureScopedDir -Name 'design'
$Debts = Join-Path (Join-Path $ctx.REPO_ROOT $ctx.DOCS_DIR) 'architecture\tech-debts.md'

$Pattern = Resolve-Auto -Key 'DD_PATTERN'               -Default 'hexagonal'
$Api     = Resolve-Auto -Key 'DD_API_STYLE'             -Default 'rest'
$Data    = Resolve-Auto -Key 'DD_DATA_STYLE'            -Default 'relational'
$IncApi  = Resolve-Auto -Key 'DD_INCLUDE_API_CONTRACT'  -Default 'true'
$IncData = Resolve-Auto -Key 'DD_INCLUDE_DATA_MODEL'    -Default 'true'

$Out = Join-Path $Dir 'design.md'

if ($env:KISS_DRY_RUN -eq '1') { Write-Host ("[dry-run] would write: {0}" -f $Out); exit 0 }
if (-not (Confirm-BeforeWrite -Message "Scaffold detailed design under $Dir.")) { Write-Error 'Aborted.'; exit 1 }
if (Test-Path -LiteralPath $Out) { Write-Error "Design exists: $Out"; exit 2 }

$feature = $ctx.CURRENT_FEATURE
$today = Get-Date -Format 'yyyy-MM-dd'

function Write-FromTemplate([string]$tpl, [string]$out, [hashtable]$subs) {
    $c = Get-Content -LiteralPath $tpl -Raw
    foreach ($k in $subs.Keys) { $c = $c.Replace($k, $subs[$k]) }
    Set-Content -LiteralPath $out -Value $c
}

Write-FromTemplate (Join-Path $SkillDir 'templates\design-template.md') $Out @{
    '{feature}'=$feature; '{date}'=$today; '{pattern}'=$Pattern; '{api_style}'=$Api; '{data_style}'=$Data
}
Write-Host ("Wrote {0}" -f $Out)

if ($IncApi -eq 'true') {
    $apiOut = Join-Path $Dir 'api-contract.md'
    if (-not (Test-Path -LiteralPath $apiOut)) {
        Write-FromTemplate (Join-Path $SkillDir 'templates\api-contract-template.md') $apiOut @{
            '{feature}'=$feature; '{api_style}'=$Api
        }
        Write-Host ("Wrote {0}" -f $apiOut)
    }
}

if ($IncData -eq 'true') {
    $dataOut = Join-Path $Dir 'data-model.md'
    if (-not (Test-Path -LiteralPath $dataOut)) {
        Write-FromTemplate (Join-Path $SkillDir 'templates\data-model-template.md') $dataOut @{
            '{feature}'=$feature; '{data_style}'=$Data
        }
        Write-Host ("Wrote {0}" -f $dataOut)
    }
}

Write-Extract -ArtefactPath $Out "FEATURE=$feature" "PATTERN=$Pattern" "API_STYLE=$Api" "DATA_STYLE=$Data" | Out-Null
Append-Debt -File $Debts -Prefix 'TDEBT' -Body "Design scaffolded for $feature — fill module structure from architecture C4 container" | Out-Null
