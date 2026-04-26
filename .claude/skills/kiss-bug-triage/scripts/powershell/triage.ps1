#!/usr/bin/env pwsh
param([switch]$Auto, [switch]$DryRun, [string]$Answers, [switch]$Help)
$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $PSCommandPath
. (Join-Path $ScriptDir 'common.ps1')
if ($Auto)    { $env:KISS_AUTO = '1' }
if ($DryRun)  { $env:KISS_DRY_RUN = '1' }
if ($Answers) { $env:KISS_ANSWERS = $Answers; Import-KissAnswers -Path $Answers }
if ($Help) { "Usage: triage.ps1 -Auto. Key: BT_STALE_DAYS." | Write-Host; exit 0 }
$ctx = Read-Context
$SkillDir = (Resolve-Path -LiteralPath (Join-Path $ScriptDir '..\..')).Path
$Dir = Join-Path (Join-Path $ctx.REPO_ROOT $ctx.DOCS_DIR) 'bugs'
$Out = Join-Path $Dir 'triage.md'

$Stale = Resolve-Auto -Key 'BT_STALE_DAYS' -Default '30'

if ($env:KISS_DRY_RUN -eq '1') { Write-Host ("[dry-run] would rewrite: {0}" -f $Out); exit 0 }
if (-not (Confirm-BeforeWrite -Message "Rewrite triage list at $Out.")) { Write-Error 'Aborted.'; exit 1 }
New-Item -ItemType Directory -Force -Path $Dir | Out-Null

$tpl = Join-Path $SkillDir 'templates\triage-template.md'
$c = Get-Content -LiteralPath $tpl -Raw
$c = $c.Replace('{date}', (Get-Date -Format 'yyyy-MM-dd')).Replace('{stale_days}', $Stale)
Set-Content -LiteralPath $Out -Value $c

$open = 0
if (Test-Path -LiteralPath $Dir) {
    $open = (Get-ChildItem -LiteralPath $Dir -Filter 'BUG-*.md' -ErrorAction SilentlyContinue).Count
}
Write-Extract -ArtefactPath $Out "DATE=$(Get-Date -Format 'yyyy-MM-dd')" "OPEN_BUGS=$open" "STALE_DAYS=$Stale" | Out-Null
Write-Host ("Wrote {0} — {1} open bugs." -f $Out, $open)
