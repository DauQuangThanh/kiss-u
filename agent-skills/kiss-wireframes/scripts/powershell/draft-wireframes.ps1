#!/usr/bin/env pwsh
param([switch]$Auto, [switch]$DryRun, [string]$Answers, [switch]$Help)
$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $PSCommandPath
. (Join-Path $ScriptDir 'common.ps1')
if ($Auto)    { $env:KISS_AUTO = '1' }
if ($DryRun)  { $env:KISS_DRY_RUN = '1' }
if ($Answers) { $env:KISS_ANSWERS = $Answers; Import-KissAnswers -Path $Answers }
if ($Help) { "Usage: draft-wireframes.ps1 -Auto. Key: UX_PERSONA." | Write-Host; exit 0 }
$ctx = Read-Context
if (-not $ctx.CURRENT_FEATURE) { Write-Error "current.feature required"; exit 2 }
$SkillDir = (Resolve-Path -LiteralPath (Join-Path $ScriptDir '..\..')).Path
$Dir = Get-FeatureScopedDir -Name 'ux'
$Wf  = Join-Path $Dir 'wireframes.md'
$Uf  = Join-Path $Dir 'user-flows.md'
$Debts = Join-Path (Join-Path $ctx.REPO_ROOT $ctx.DOCS_DIR) 'ux\ux-debts.md'
$Persona = Resolve-Auto -Key 'UX_PERSONA' -Default 'end user'

if ($env:KISS_DRY_RUN -eq '1') { Write-Host ("[dry-run] would write: {0} + {1}" -f $Wf, $Uf); exit 0 }
if (-not (Confirm-BeforeWrite -Message "Scaffold wireframes + flows under $Dir.")) { Write-Error 'Aborted.'; exit 1 }

foreach ($pair in @(@($Wf, 'wireframes-template.md'), @($Uf, 'user-flows-template.md'))) {
    $out = $pair[0]
    if (Test-Path -LiteralPath $out) { continue }
    $tpl = Join-Path $SkillDir ("templates\" + $pair[1])
    $c = Get-Content -LiteralPath $tpl -Raw
    $c = $c.Replace('{feature}', $ctx.CURRENT_FEATURE).Replace('{date}', (Get-Date -Format 'yyyy-MM-dd')).Replace('{persona}', $Persona)
    Set-Content -LiteralPath $out -Value $c
    Write-Host ("Wrote {0}" -f $out)
}

Write-Extract -ArtefactPath $Wf "FEATURE=$($ctx.CURRENT_FEATURE)" "PERSONA=$Persona" | Out-Null
Append-Debt -File $Debts -Prefix 'UXDEBT' -Body "Wireframes + flows scaffolded for $($ctx.CURRENT_FEATURE)" | Out-Null
