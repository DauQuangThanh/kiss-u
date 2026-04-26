#!/usr/bin/env pwsh
param([switch]$Auto, [switch]$DryRun, [string]$Answers, [switch]$Help)
$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $PSCommandPath
. (Join-Path $ScriptDir 'common.ps1')
if ($Auto)    { $env:KISS_AUTO = '1' }
if ($DryRun)  { $env:KISS_DRY_RUN = '1' }
if ($Answers) { $env:KISS_ANSWERS = $Answers; Import-KissAnswers -Path $Answers }
if ($Help) { "Usage: draft-monitoring.ps1 -Auto. Keys: MON_STACK, MON_SLO_AVAILABILITY, MON_SLO_P95_MS." | Write-Host; exit 0 }
$ctx = Read-Context
$SkillDir = (Resolve-Path -LiteralPath (Join-Path $ScriptDir '..\..')).Path
$Dir = Join-Path (Join-Path $ctx.REPO_ROOT $ctx.DOCS_DIR) 'operations'
$Out = Join-Path $Dir 'monitoring.md'
$Stack = Resolve-Auto -Key 'MON_STACK'            -Default 'otel'
$Avail = Resolve-Auto -Key 'MON_SLO_AVAILABILITY' -Default '99.9'
$P95   = Resolve-Auto -Key 'MON_SLO_P95_MS'       -Default '300'
if ($env:KISS_DRY_RUN -eq '1') { Write-Host ("[dry-run] stack={0}" -f $Stack); exit 0 }
if (Test-Path -LiteralPath $Out) { Write-Error "Monitoring doc exists: $Out"; exit 2 }
if (-not (Confirm-BeforeWrite -Message "Scaffold monitoring doc at $Out.")) { Write-Error 'Aborted.'; exit 1 }
New-Item -ItemType Directory -Force -Path $Dir | Out-Null
$tpl = Join-Path $SkillDir 'templates\monitoring-template.md'
$c = Get-Content -LiteralPath $tpl -Raw
$c = $c.Replace('{date}', (Get-Date -Format 'yyyy-MM-dd')).Replace('{stack}', $Stack).Replace('{slo_avail}', $Avail).Replace('{slo_p95_ms}', $P95)
Set-Content -LiteralPath $Out -Value $c
Write-Extract -ArtefactPath $Out "STACK=$Stack" "SLO_AVAILABILITY=$Avail" "SLO_P95_MS=$P95" | Out-Null
Write-Host ("Wrote {0}" -f $Out)
