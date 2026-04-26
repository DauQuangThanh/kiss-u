#!/usr/bin/env pwsh
param([switch]$Auto, [switch]$DryRun, [string]$Answers, [switch]$Help)
$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $PSCommandPath
. (Join-Path $ScriptDir 'common.ps1')
if ($Auto)    { $env:KISS_AUTO = '1' }
if ($DryRun)  { $env:KISS_DRY_RUN = '1' }
if ($Answers) { $env:KISS_ANSWERS = $Answers; Import-KissAnswers -Path $Answers }
if ($Help) { "Usage: draft-containers.ps1 -Auto. Keys: CONT_RUNTIME, CONT_BASE_IMAGE." | Write-Host; exit 0 }
$ctx = Read-Context
$SkillDir = (Resolve-Path -LiteralPath (Join-Path $ScriptDir '..\..')).Path
$Dir = Join-Path (Join-Path $ctx.REPO_ROOT $ctx.DOCS_DIR) 'operations'
$Out = Join-Path $Dir 'containers.md'
$detect = 'unknown'
$root = $ctx.REPO_ROOT
if (Test-Path (Join-Path $root 'package.json')) { $detect = 'node' }
elseif (Test-Path (Join-Path $root 'pyproject.toml')) { $detect = 'python' }
elseif (Test-Path (Join-Path $root 'go.mod')) { $detect = 'go' }
elseif (Test-Path (Join-Path $root 'Cargo.toml')) { $detect = 'rust' }
elseif (Test-Path (Join-Path $root 'pom.xml')) { $detect = 'java' }

$Runtime = Resolve-Auto -Key 'CONT_RUNTIME'    -Default $detect
$Base    = Resolve-Auto -Key 'CONT_BASE_IMAGE' -Default 'slim'

if ($env:KISS_DRY_RUN -eq '1') { Write-Host ("[dry-run] runtime={0} base={1}" -f $Runtime, $Base); exit 0 }
if (Test-Path -LiteralPath $Out) { Write-Error "Containers doc exists: $Out"; exit 2 }
if (-not (Confirm-BeforeWrite -Message "Scaffold containers doc at $Out.")) { Write-Error 'Aborted.'; exit 1 }
New-Item -ItemType Directory -Force -Path $Dir | Out-Null
$tpl = Join-Path $SkillDir 'templates\containers-template.md'
$c = Get-Content -LiteralPath $tpl -Raw
$c = $c.Replace('{date}', (Get-Date -Format 'yyyy-MM-dd')).Replace('{runtime}', $Runtime).Replace('{base_image}', $Base)
Set-Content -LiteralPath $Out -Value $c
Write-Extract -ArtefactPath $Out "RUNTIME=$Runtime" "BASE_IMAGE=$Base" | Out-Null
Write-Host ("Wrote {0}" -f $Out)
