#!/usr/bin/env pwsh
param(
    [switch]$Auto, [switch]$DryRun, [string]$Answers, [switch]$Help
)
$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $PSCommandPath
. (Join-Path $ScriptDir 'common.ps1')

if ($Auto)    { $env:KISS_AUTO = '1' }
if ($DryRun)  { $env:KISS_DRY_RUN = '1' }
if ($Answers) { $env:KISS_ANSWERS = $Answers; Import-KissAnswers -Path $Answers }

if ($Help) {
    "Usage: draft-acceptance.ps1 [-Auto] [-Answers FILE] [-DryRun] [-Help]`nScaffolds docs/product/acceptance.md for the active feature." | Write-Host
    exit 0
}

$ctx = Read-Context
$SkillDir = (Resolve-Path -LiteralPath (Join-Path $ScriptDir '..\..')).Path
$Dir      = Join-Path (Join-Path $ctx.REPO_ROOT $ctx.DOCS_DIR) 'product'
$Out      = Join-Path $Dir 'acceptance.md'
$Debts    = Join-Path $Dir 'product-debts.md'

if (-not $ctx.CURRENT_FEATURE) {
    Write-Error ".kiss/context.yml current.feature is not set — run kiss.specify first."
    exit 2
}
$feature = $ctx.CURRENT_FEATURE
$specRef = "$($ctx.SPECS_DIR)/$feature/spec.md"

if ($env:KISS_DRY_RUN -eq '1') {
    Write-Host ("[dry-run] would write: {0}" -f $Out)
    Write-Host ("[dry-run] feature: {0}" -f $feature)
    exit 0
}

if (-not (Confirm-BeforeWrite -Message "Scaffold acceptance criteria at $Out.")) { Write-Error 'Aborted.'; exit 1 }

New-Item -ItemType Directory -Force -Path $Dir | Out-Null
if (Test-Path -LiteralPath $Out) {
    Write-Error "Acceptance file already exists: $Out (edit in place)."
    exit 2
}

$tpl = Join-Path $SkillDir 'templates\acceptance-template.md'
$c = Get-Content -LiteralPath $tpl -Raw
$c = $c.Replace('{feature}', $feature).Replace('{date}', (Get-Date -Format 'yyyy-MM-dd')).Replace('{spec_ref}', $specRef)
Set-Content -LiteralPath $Out -Value $c

Write-Extract -ArtefactPath $Out "FEATURE=$feature" "SPEC_REF=$specRef" | Out-Null
Write-Host ("Wrote {0}" -f $Out)
Append-Debt -File $Debts -Prefix 'PODEBT' -Body "Acceptance scaffolded for $feature — populate Given/When/Then blocks per user story" | Out-Null
