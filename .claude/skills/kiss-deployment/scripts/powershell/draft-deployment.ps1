#!/usr/bin/env pwsh
param([switch]$Auto, [switch]$DryRun, [string]$Answers, [switch]$Help)
$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $PSCommandPath
. (Join-Path $ScriptDir 'common.ps1')
if ($Auto)    { $env:KISS_AUTO = '1' }
if ($DryRun)  { $env:KISS_DRY_RUN = '1' }
if ($Answers) { $env:KISS_ANSWERS = $Answers; Import-KissAnswers -Path $Answers }
if ($Help) { "Usage: draft-deployment.ps1 -Auto. Keys: DP_MODEL, DP_CANARY_BAKE_MIN, DP_ENVIRONMENTS." | Write-Host; exit 0 }
$ctx = Read-Context
$SkillDir = (Resolve-Path -LiteralPath (Join-Path $ScriptDir '..\..')).Path
$Dir = Join-Path (Join-Path $ctx.REPO_ROOT $ctx.DOCS_DIR) 'operations'
$Out = Join-Path $Dir 'deployment.md'
$Model = Resolve-Auto -Key 'DP_MODEL'            -Default 'canary'
$Bake  = Resolve-Auto -Key 'DP_CANARY_BAKE_MIN'  -Default '30'
$Envs  = Resolve-Auto -Key 'DP_ENVIRONMENTS'     -Default 'dev,staging,prod'
if ($env:KISS_DRY_RUN -eq '1') { Write-Host ("[dry-run] model={0}" -f $Model); exit 0 }
if (Test-Path -LiteralPath $Out) { Write-Error "Deployment doc exists: $Out"; exit 2 }
if (-not (Confirm-BeforeWrite -Message "Scaffold deployment doc at $Out.")) { Write-Error 'Aborted.'; exit 1 }
New-Item -ItemType Directory -Force -Path $Dir | Out-Null
$tpl = Join-Path $SkillDir 'templates\deployment-template.md'
$c = Get-Content -LiteralPath $tpl -Raw
$c = $c.Replace('{date}', (Get-Date -Format 'yyyy-MM-dd')).Replace('{model}', $Model).Replace('{bake_min}', $Bake).Replace('{envs}', $Envs)
Set-Content -LiteralPath $Out -Value $c
Write-Extract -ArtefactPath $Out "MODEL=$Model" "BAKE_MIN=$Bake" "ENVIRONMENTS=$Envs" | Out-Null
Write-Host ("Wrote {0}" -f $Out)
