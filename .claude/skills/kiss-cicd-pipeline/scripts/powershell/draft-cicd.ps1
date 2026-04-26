#!/usr/bin/env pwsh
param([switch]$Auto, [switch]$DryRun, [string]$Answers, [switch]$Help)
$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $PSCommandPath
. (Join-Path $ScriptDir 'common.ps1')
if ($Auto)    { $env:KISS_AUTO = '1' }
if ($DryRun)  { $env:KISS_DRY_RUN = '1' }
if ($Answers) { $env:KISS_ANSWERS = $Answers; Import-KissAnswers -Path $Answers }
if ($Help) { "Usage: draft-cicd.ps1 -Auto. Keys: CI_PROVIDER, CI_REQUIRES_MANUAL_RELEASE." | Write-Host; exit 0 }
$ctx = Read-Context
$SkillDir = (Resolve-Path -LiteralPath (Join-Path $ScriptDir '..\..')).Path
$Dir = Join-Path (Join-Path $ctx.REPO_ROOT $ctx.DOCS_DIR) 'operations'
$Out = Join-Path $Dir 'cicd.md'
$Prov   = Resolve-Auto -Key 'CI_PROVIDER'                -Default 'github-actions'
$Manual = Resolve-Auto -Key 'CI_REQUIRES_MANUAL_RELEASE' -Default 'true'
if ($env:KISS_DRY_RUN -eq '1') { Write-Host ("[dry-run] would write: {0}" -f $Out); exit 0 }
if (Test-Path -LiteralPath $Out) { Write-Error "CI/CD doc exists: $Out"; exit 2 }
if (-not (Confirm-BeforeWrite -Message "Scaffold CI/CD doc at $Out.")) { Write-Error 'Aborted.'; exit 1 }
New-Item -ItemType Directory -Force -Path $Dir | Out-Null
$tpl = Join-Path $SkillDir 'templates\cicd-template.md'
$c = Get-Content -LiteralPath $tpl -Raw
$c = $c.Replace('{date}', (Get-Date -Format 'yyyy-MM-dd')).Replace('{provider}', $Prov).Replace('{manual_release}', $Manual)
Set-Content -LiteralPath $Out -Value $c
Write-Extract -ArtefactPath $Out "PROVIDER=$Prov" "MANUAL_RELEASE=$Manual" | Out-Null
Write-Host ("Wrote {0}" -f $Out)
