#!/usr/bin/env pwsh
param([switch]$Auto, [switch]$DryRun, [string]$Answers, [switch]$Help)
$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $PSCommandPath
. (Join-Path $ScriptDir 'common.ps1')
if ($Auto)    { $env:KISS_AUTO = '1' }
if ($DryRun)  { $env:KISS_DRY_RUN = '1' }
if ($Answers) { $env:KISS_ANSWERS = $Answers; Import-KissAnswers -Path $Answers }
if ($Help) { "Usage: audit.ps1 -Auto. Keys: DA_LICENCE_POLICY, DA_MAX_AGE_DAYS." | Write-Host; exit 0 }
$ctx = Read-Context
$SkillDir = (Resolve-Path -LiteralPath (Join-Path $ScriptDir '..\..')).Path
$Feature = if ($ctx.CURRENT_FEATURE) { $ctx.CURRENT_FEATURE } else { 'project' }
$Dir = Join-Path (Join-Path (Join-Path $ctx.REPO_ROOT $ctx.DOCS_DIR) 'reviews') $Feature
$Out = Join-Path $Dir 'dependencies.md'

$Policy = Resolve-Auto -Key 'DA_LICENCE_POLICY' -Default 'MIT,Apache-2.0,BSD-3-Clause,BSD-2-Clause,ISC'

$lockfile = '(none detected)'
foreach ($lf in 'uv.lock','poetry.lock','package-lock.json','pnpm-lock.yaml','yarn.lock','go.sum','Cargo.lock','pom.xml','Gemfile.lock','mix.lock') {
    if (Test-Path -LiteralPath (Join-Path $ctx.REPO_ROOT $lf)) { $lockfile = $lf; break }
}

if ($env:KISS_DRY_RUN -eq '1') { Write-Host ("[dry-run] lockfile={0}" -f $lockfile); exit 0 }
if (-not (Confirm-BeforeWrite -Message "Scaffold dependency audit at $Out.")) { Write-Error 'Aborted.'; exit 1 }
New-Item -ItemType Directory -Force -Path $Dir | Out-Null
if (Test-Path -LiteralPath $Out) { Write-Error "Audit exists: $Out"; exit 2 }

$tpl = Join-Path $SkillDir 'templates\dependency-audit-template.md'
$c = Get-Content -LiteralPath $tpl -Raw
$c = $c.Replace('{feature}', $Feature).Replace('{date}', (Get-Date -Format 'yyyy-MM-dd')).Replace('{lockfile}', $lockfile).Replace('{licence_policy}', $Policy)
Set-Content -LiteralPath $Out -Value $c
Write-Extract -ArtefactPath $Out "FEATURE=$Feature" "LOCKFILE=$lockfile" "LICENCE_POLICY=$Policy" | Out-Null
Write-Host ("Wrote {0}" -f $Out)
