#!/usr/bin/env pwsh
param([switch]$Auto, [switch]$DryRun, [string]$Answers, [switch]$Help)
$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $PSCommandPath
. (Join-Path $ScriptDir 'common.ps1')
if ($Auto)    { $env:KISS_AUTO = '1' }
if ($DryRun)  { $env:KISS_DRY_RUN = '1' }
if ($Answers) { $env:KISS_ANSWERS = $Answers; Import-KissAnswers -Path $Answers }
if ($Help) { "Usage: add-bug.ps1 -Auto. Keys: BUG_TITLE, BUG_STEPS, BUG_EXPECTED, BUG_ACTUAL, BUG_SEVERITY, BUG_PRIORITY, BUG_AFFECTED_VERSION, BUG_FAILED_TC, BUG_USER_STORY." | Write-Host; exit 0 }

$ctx = Read-Context
$SkillDir = (Resolve-Path -LiteralPath (Join-Path $ScriptDir '..\..')).Path
$Dir = Join-Path (Join-Path $ctx.REPO_ROOT $ctx.DOCS_DIR) 'bugs'

$Title    = Resolve-Auto -Key 'BUG_TITLE'            -Default ''
$Steps    = Resolve-Auto -Key 'BUG_STEPS'            -Default ''
$Expected = Resolve-Auto -Key 'BUG_EXPECTED'         -Default ''
$Actual   = Resolve-Auto -Key 'BUG_ACTUAL'           -Default ''
$Sev      = Resolve-Auto -Key 'BUG_SEVERITY'         -Default 'medium'
$Prio     = Resolve-Auto -Key 'BUG_PRIORITY'         -Default 'medium'
$Ver      = Resolve-Auto -Key 'BUG_AFFECTED_VERSION' -Default ''
$Tc       = Resolve-Auto -Key 'BUG_FAILED_TC'        -Default ''
$Us       = Resolve-Auto -Key 'BUG_USER_STORY'       -Default ''

foreach ($pair in @(@('BUG_TITLE',$Title),@('BUG_STEPS',$Steps),@('BUG_EXPECTED',$Expected),@('BUG_ACTUAL',$Actual))) {
    if (-not $pair[1]) { Write-Error "$($pair[0]) required"; exit 2 }
}

$next = 1
if (Test-Path -LiteralPath $Dir) {
    $nums = Get-ChildItem -LiteralPath $Dir -Filter 'BUG-*.md' -ErrorAction SilentlyContinue |
        ForEach-Object { if ($_.Name -match '^BUG-(\d+)') { [int]$Matches[1] } }
    if ($nums) { $next = ($nums | Measure-Object -Maximum).Maximum + 1 }
}
$num = '{0:D3}' -f $next
$slug = ($Title.ToLower() -replace '[^a-z0-9]+', '-').Trim('-')
if ($slug.Length -gt 60) { $slug = $slug.Substring(0, 60) }
$Out = Join-Path $Dir ("BUG-{0}-{1}.md" -f $num, $slug)

if ($env:KISS_DRY_RUN -eq '1') { Write-Host ("[dry-run] would write: {0}" -f $Out); exit 0 }
if (-not (Confirm-BeforeWrite -Message "Write bug report $num at $Out.")) { Write-Error 'Aborted.'; exit 1 }
New-Item -ItemType Directory -Force -Path $Dir | Out-Null

# Expand \n escapes in $Steps
$StepsExpanded = $Steps -replace '\\n', "`n"

$tpl = Get-Content -LiteralPath (Join-Path $SkillDir 'templates\bug-template.md') -Raw
$c = $tpl.Replace('{number}', $num).Replace('{title}', $Title).Replace('{date}', (Get-Date -Format 'yyyy-MM-dd'))
$c = $c.Replace('{severity}', $Sev).Replace('{priority}', $Prio)
$c = $c.Replace('{failed_tc}', $(if ($Tc) { $Tc } else { '<none>' }))
$c = $c.Replace('{user_story}', $(if ($Us) { $Us } else { '<none>' }))
$c = $c.Replace('{affected_version}', $(if ($Ver) { $Ver } else { '<unknown>' }))
$c = $c.Replace('{steps}', $StepsExpanded).Replace('{expected}', $Expected).Replace('{actual}', $Actual)
Set-Content -LiteralPath $Out -Value $c

Write-Extract -ArtefactPath $Out "BUG_ID=BUG-$num" "SEVERITY=$Sev" "PRIORITY=$Prio" "FAILED_TC=$Tc" "USER_STORY=$Us" | Out-Null
Write-Host ("Wrote {0}" -f $Out)
