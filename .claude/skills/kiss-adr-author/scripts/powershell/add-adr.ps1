#!/usr/bin/env pwsh
param([switch]$Auto, [switch]$DryRun, [string]$Answers, [switch]$Help)
$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $PSCommandPath
. (Join-Path $ScriptDir 'common.ps1')
if ($Auto)    { $env:KISS_AUTO = '1' }
if ($DryRun)  { $env:KISS_DRY_RUN = '1' }
if ($Answers) { $env:KISS_ANSWERS = $Answers; Import-KissAnswers -Path $Answers }
if ($Help) { "Usage: add-adr.ps1 -Auto. Keys: ADR_TITLE, ADR_DECIDER, ADR_CONTEXT, ADR_DECISION, ADR_CONSEQUENCES, ADR_STATUS, ADR_SUPERSEDES." | Write-Host; exit 0 }

$ctx = Read-Context
$SkillDir = (Resolve-Path -LiteralPath (Join-Path $ScriptDir '..\..')).Path
$Dir      = Join-Path (Join-Path $ctx.REPO_ROOT $ctx.DOCS_DIR) 'decisions'
$Debts    = Join-Path (Join-Path $ctx.REPO_ROOT $ctx.DOCS_DIR) 'architecture\tech-debts.md'

$Title    = Resolve-Auto -Key 'ADR_TITLE'        -Default ''
$Decider  = Resolve-Auto -Key 'ADR_DECIDER'      -Default ''
$Context  = Resolve-Auto -Key 'ADR_CONTEXT'      -Default ''
$Decision = Resolve-Auto -Key 'ADR_DECISION'     -Default ''
$Conseq   = Resolve-Auto -Key 'ADR_CONSEQUENCES' -Default ''
$Status   = Resolve-Auto -Key 'ADR_STATUS'       -Default 'Proposed'
$Sup      = Resolve-Auto -Key 'ADR_SUPERSEDES'   -Default ''

if ($Status -notin @('Proposed','Accepted','Deprecated','Superseded')) { $Status = 'Proposed' }
if (-not $Title) { Write-Error "ADR_TITLE required"; exit 2 }

$next = 1
if (Test-Path -LiteralPath $Dir) {
    $nums = Get-ChildItem -LiteralPath $Dir -Filter 'ADR-*.md' -ErrorAction SilentlyContinue |
        ForEach-Object { if ($_.Name -match '^ADR-(\d+)') { [int]$Matches[1] } }
    if ($nums) { $next = ($nums | Measure-Object -Maximum).Maximum + 1 }
}
$num = '{0:D3}' -f $next
$slug = ($Title.ToLower() -replace '[^a-z0-9]+', '-').Trim('-')
if ($slug.Length -gt 60) { $slug = $slug.Substring(0, 60) }
$Out = Join-Path $Dir ("ADR-{0}-{1}.md" -f $num, $slug)
$supLine = if ($Sup) { "**Supersedes:** $Sup" } else { '' }

if ($env:KISS_DRY_RUN -eq '1') { Write-Host ("[dry-run] would write: {0}" -f $Out); exit 0 }
if (-not (Confirm-BeforeWrite -Message "Write ADR $num at $Out.")) { Write-Error 'Aborted.'; exit 1 }
New-Item -ItemType Directory -Force -Path $Dir | Out-Null
if (Test-Path -LiteralPath $Out) { Write-Error "ADR already exists: $Out"; exit 2 }

$tpl = Get-Content -LiteralPath (Join-Path $SkillDir 'templates\adr-template.md') -Raw
$c = $tpl.Replace('{number}', $num).Replace('{title}', $Title).Replace('{date}', (Get-Date -Format 'yyyy-MM-dd'))
$c = $c.Replace('{status}', $Status).Replace('{decider}', $(if ($Decider) { $Decider } else { '<TBD>' }))
$c = $c.Replace('{supersedes_line}', $supLine)
$c = $c.Replace('{context}', $(if ($Context) { $Context } else { '<TBD>' }))
$c = $c.Replace('{decision}', $(if ($Decision) { $Decision } else { '<TBD>' }))
$c = $c.Replace('{consequences}', $(if ($Conseq) { $Conseq } else { '<TBD>' }))
Set-Content -LiteralPath $Out -Value $c

Write-Extract -ArtefactPath $Out "ADR_ID=ADR-$num" "TITLE=$Title" "STATUS=$Status" "DECIDER=$Decider" | Out-Null
Write-Host ("Wrote {0}" -f $Out)

if (-not $Context -or -not $Decision) {
    Append-Debt -File $Debts -Prefix 'TDEBT' -Body "ADR-$num ('$Title') has incomplete context or decision" | Out-Null
}
