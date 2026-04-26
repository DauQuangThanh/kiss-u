#!/usr/bin/env pwsh
param([switch]$Auto, [switch]$DryRun, [string]$Answers, [switch]$Help)
$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $PSCommandPath
. (Join-Path $ScriptDir 'common.ps1')
if ($Auto)    { $env:KISS_AUTO = '1' }
if ($DryRun)  { $env:KISS_DRY_RUN = '1' }
if ($Answers) { $env:KISS_ANSWERS = $Answers; Import-KissAnswers -Path $Answers }
if ($Help) { "Usage: draft-research.ps1 -Auto|-Help. Keys: TR_TOPIC, TR_CANDIDATES." | Write-Host; exit 0 }

$ctx = Read-Context
$SkillDir = (Resolve-Path -LiteralPath (Join-Path $ScriptDir '..\..')).Path
$Dir      = Join-Path (Join-Path $ctx.REPO_ROOT $ctx.DOCS_DIR) 'research'
$Debts    = Join-Path (Join-Path $ctx.REPO_ROOT $ctx.DOCS_DIR) 'architecture\tech-debts.md'

$Topic = Resolve-Auto -Key 'TR_TOPIC'      -Default ''
$Cands = Resolve-Auto -Key 'TR_CANDIDATES' -Default ''
if (-not $Topic) { Write-Error "TR_TOPIC required"; exit 2 }
if (-not $Cands) { Write-Error "TR_CANDIDATES required"; exit 2 }

$Out = Join-Path $Dir ("{0}.md" -f $Topic)

$rows = "| Candidate | Pros | Cons | Cost signal |`n|---|---|---|---|`n"
foreach ($c in ($Cands -split ',')) {
    $rows += "| $($c.Trim()) | <pros> | <cons> | <cost> |`n"
}

if ($env:KISS_DRY_RUN -eq '1') { Write-Host ("[dry-run] would write: {0}" -f $Out); exit 0 }
if (-not (Confirm-BeforeWrite -Message "Scaffold research at $Out.")) { Write-Error 'Aborted.'; exit 1 }
New-Item -ItemType Directory -Force -Path $Dir | Out-Null
if (Test-Path -LiteralPath $Out) { Write-Error "File exists: $Out"; exit 2 }

$tpl = Join-Path $SkillDir 'templates\research-template.md'
$c = Get-Content -LiteralPath $tpl -Raw
$c = $c.Replace('{topic}', $Topic).Replace('{date}', (Get-Date -Format 'yyyy-MM-dd')).Replace('{candidate_rows}', $rows)
Set-Content -LiteralPath $Out -Value $c

Write-Extract -ArtefactPath $Out "TOPIC=$Topic" "CANDIDATES=$Cands" | Out-Null
Append-Debt -File $Debts -Prefix 'TDEBT' -Body "Research scaffolded for '$Topic' — candidates: $Cands" | Out-Null
Write-Host ("Wrote {0}" -f $Out)
