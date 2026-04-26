#!/usr/bin/env pwsh
param([switch]$Auto, [switch]$DryRun, [string]$Answers, [switch]$Help)
$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $PSCommandPath
. (Join-Path $ScriptDir 'common.ps1')
if ($Auto)    { $env:KISS_AUTO = '1' }
if ($DryRun)  { $env:KISS_DRY_RUN = '1' }
if ($Answers) { $env:KISS_ANSWERS = $Answers; Import-KissAnswers -Path $Answers }
if ($Help) { "Usage: draft-intake.ps1 [-Auto] [-Answers FILE] [-DryRun] [-Help]" | Write-Host; exit 0 }

$ctx = Read-Context
$SkillDir = (Resolve-Path -LiteralPath (Join-Path $ScriptDir '..\..')).Path
$Dir      = Join-Path (Join-Path $ctx.REPO_ROOT $ctx.DOCS_DIR) 'architecture'
$Out      = Join-Path $Dir 'intake.md'
$Debts    = Join-Path $Dir 'tech-debts.md'

$Team   = Resolve-Auto -Key 'AI_TEAM_SIZE_BAND' -Default '6-15'
$Qps    = Resolve-Auto -Key 'AI_PEAK_QPS'       -Default ''
$Sla    = Resolve-Auto -Key 'AI_SLA_TARGET'     -Default '99.9%'
$Deploy = Resolve-Auto -Key 'AI_DEPLOY_PREF'    -Default 'no-preference'

if ($env:KISS_DRY_RUN -eq '1') { Write-Host ("[dry-run] would write: {0}" -f $Out); exit 0 }
if (-not (Confirm-BeforeWrite -Message "Scaffold intake at $Out.")) { Write-Error 'Aborted.'; exit 1 }
New-Item -ItemType Directory -Force -Path $Dir | Out-Null
if (Test-Path -LiteralPath $Out) { Write-Error "Intake exists: $Out"; exit 2 }

$tpl = Join-Path $SkillDir 'templates\intake-template.md'
$c = Get-Content -LiteralPath $tpl -Raw
$c = $c.Replace('{date}', (Get-Date -Format 'yyyy-MM-dd'))
$c = $c.Replace('{feature}', $(if ($ctx.CURRENT_FEATURE) { $ctx.CURRENT_FEATURE } else { '<none>' }))
$c = $c.Replace('{team_size_band}', $Team).Replace('{peak_qps}', $(if ($Qps) { $Qps } else { '<TBD>' })).Replace('{sla_target}', $Sla).Replace('{deploy_pref}', $Deploy)
Set-Content -LiteralPath $Out -Value $c
Write-Extract -ArtefactPath $Out "TEAM_SIZE_BAND=$Team" "SLA_TARGET=$Sla" "DEPLOY_PREF=$Deploy" "PEAK_QPS=$Qps" | Out-Null
Write-Host ("Wrote {0}" -f $Out)
if (-not $Qps) { Append-Debt -File $Debts -Prefix 'TDEBT' -Body "Peak QPS not provided (Priority: 🟡 Important)" | Out-Null }
