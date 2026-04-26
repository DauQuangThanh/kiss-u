#!/usr/bin/env pwsh
param([switch]$Auto, [switch]$DryRun, [string]$Answers, [switch]$Help)
$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $PSCommandPath
. (Join-Path $ScriptDir 'common.ps1')
if ($Auto)    { $env:KISS_AUTO = '1' }
if ($DryRun)  { $env:KISS_DRY_RUN = '1' }
if ($Answers) { $env:KISS_ANSWERS = $Answers; Import-KissAnswers -Path $Answers }
if ($Help) { "Usage: review.ps1 -Auto. Keys: SR_SCOPE, SR_COMPLIANCE, SR_THREAT_MODEL." | Write-Host; exit 0 }
$ctx = Read-Context
if (-not $ctx.CURRENT_FEATURE) { Write-Error "current.feature required"; exit 2 }
$SkillDir = (Resolve-Path -LiteralPath (Join-Path $ScriptDir '..\..')).Path
$Dir = Get-FeatureScopedDir -Name 'reviews'
$Out = Join-Path $Dir 'security.md'

$Scope = Resolve-Auto -Key 'SR_SCOPE'         -Default 'src/**'
$Comp  = Resolve-Auto -Key 'SR_COMPLIANCE'    -Default ''
$Tm    = Resolve-Auto -Key 'SR_THREAT_MODEL'  -Default 'stride'

$compNotes = if ($Comp) {
    (($Comp -split ',') | ForEach-Object { "- **$($_.Trim())** — review data flow for applicable controls." }) -join "`n"
} else {
    "- (none specified)"
}

if ($env:KISS_DRY_RUN -eq '1') { Write-Host ("[dry-run] would write: {0}" -f $Out); exit 0 }
if (Test-Path -LiteralPath $Out) { Write-Error "Security review exists: $Out"; exit 2 }
if (-not (Confirm-BeforeWrite -Message "Scaffold security review at $Out.")) { Write-Error 'Aborted.'; exit 1 }

$tpl = Join-Path $SkillDir 'templates\security-review-template.md'
$c = Get-Content -LiteralPath $tpl -Raw
$c = $c.Replace('{feature}', $ctx.CURRENT_FEATURE).Replace('{date}', (Get-Date -Format 'yyyy-MM-dd'))
$c = $c.Replace('{scope}', $Scope).Replace('{compliance}', $(if ($Comp) { $Comp } else { 'none' })).Replace('{threat_model}', $Tm)
$c = $c.Replace('{compliance_notes}', $compNotes)
Set-Content -LiteralPath $Out -Value $c
Write-Extract -ArtefactPath $Out "FEATURE=$($ctx.CURRENT_FEATURE)" "SCOPE=$Scope" "COMPLIANCE=$Comp" "THREAT_MODEL=$Tm" | Out-Null
Write-Host ("Wrote {0}" -f $Out)
