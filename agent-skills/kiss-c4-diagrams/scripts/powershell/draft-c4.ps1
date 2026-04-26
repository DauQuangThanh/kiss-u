#!/usr/bin/env pwsh
param([switch]$Auto, [switch]$DryRun, [string]$Answers, [switch]$Help)
$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $PSCommandPath
. (Join-Path $ScriptDir 'common.ps1')
if ($Auto)    { $env:KISS_AUTO = '1' }
if ($DryRun)  { $env:KISS_DRY_RUN = '1' }
if ($Answers) { $env:KISS_ANSWERS = $Answers; Import-KissAnswers -Path $Answers }
if ($Help) { "Usage: draft-c4.ps1 -Auto. Keys: C4_LEVEL, C4_SYSTEM_NAME." | Write-Host; exit 0 }

$ctx = Read-Context
$SkillDir = (Resolve-Path -LiteralPath (Join-Path $ScriptDir '..\..')).Path
$Dir      = Join-Path (Join-Path $ctx.REPO_ROOT $ctx.DOCS_DIR) 'architecture'
$Debts    = Join-Path $Dir 'tech-debts.md'

$Level = Resolve-Auto -Key 'C4_LEVEL'       -Default 'all'
$Sys   = Resolve-Auto -Key 'C4_SYSTEM_NAME' -Default $(if ($ctx.CURRENT_FEATURE) { $ctx.CURRENT_FEATURE } else { 'system' })
if ($Level -notin @('context','container','component','all')) { $Level = 'all' }

if ($env:KISS_DRY_RUN -eq '1') { Write-Host ("[dry-run] level={0} system={1}" -f $Level, $Sys); exit 0 }
if (-not (Confirm-BeforeWrite -Message "Scaffold C4 diagrams under $Dir.")) { Write-Error 'Aborted.'; exit 1 }
New-Item -ItemType Directory -Force -Path $Dir | Out-Null

$pairs = @{
    'context'   = @('c4-context-template.md',   'c4-context.md')
    'container' = @('c4-container-template.md', 'c4-container.md')
    'component' = @('c4-component-template.md', 'c4-component.md')
}

$any = $false
foreach ($key in @('context','container','component')) {
    if ($Level -ne 'all' -and $Level -ne $key) { continue }
    $tpl = Join-Path $SkillDir ("templates\" + $pairs[$key][0])
    $out = Join-Path $Dir $pairs[$key][1]
    if (Test-Path -LiteralPath $out) { Write-Host ("Skip {0} (exists)" -f $out); continue }
    $c = Get-Content -LiteralPath $tpl -Raw
    $c = $c.Replace('{date}', (Get-Date -Format 'yyyy-MM-dd')).Replace('{system_name}', $Sys)
    Set-Content -LiteralPath $out -Value $c
    Write-Host ("Wrote {0}" -f $out)
    $any = $true
}

if ($any) { Append-Debt -File $Debts -Prefix 'TDEBT' -Body "C4 diagrams scaffolded for '$Sys'" | Out-Null }
