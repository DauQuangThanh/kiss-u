#!/usr/bin/env pwsh
# kiss-backlog PowerShell parity of add-item.sh.

param(
    [switch]$Auto,
    [switch]$DryRun,
    [string]$Answers,
    [switch]$Help
)

$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $PSCommandPath
. (Join-Path $ScriptDir 'common.ps1')

if ($Auto)    { $env:KISS_AUTO = '1' }
if ($DryRun)  { $env:KISS_DRY_RUN = '1' }
if ($Answers) { $env:KISS_ANSWERS = $Answers; Import-KissAnswers -Path $Answers }

if ($Help) {
    @'
Usage: add-item.ps1 [-Auto] [-Answers FILE] [-DryRun] [-Help]
Appends a backlog item to docs/product/backlog.md.
Answer keys: BL_TITLE, BL_PRIORITY, BL_SIZE, BL_STATUS, BL_STORY_REF.
'@ | Write-Host
    exit 0
}

$ctx = Read-Context
$SkillDir  = (Resolve-Path -LiteralPath (Join-Path $ScriptDir '..\..')).Path
$Dir       = Join-Path (Join-Path $ctx.REPO_ROOT $ctx.DOCS_DIR) 'product'
$Backlog   = Join-Path $Dir 'backlog.md'
$Debts     = Join-Path $Dir 'product-debts.md'

$Title     = Resolve-Auto -Key 'BL_TITLE'     -Default ''
$Priority  = Resolve-Auto -Key 'BL_PRIORITY'  -Default '99'
$Size      = Resolve-Auto -Key 'BL_SIZE'      -Default 'M'
$Status    = Resolve-Auto -Key 'BL_STATUS'    -Default 'New'
$StoryRef  = Resolve-Auto -Key 'BL_STORY_REF' -Default ''

if ($Size -notin @('XS','S','M','L','XL')) { $Size = 'M' }
if ($Status -notin @('New','Ready','In progress','Done','Cut')) { $Status = 'New' }

if ($env:KISS_DRY_RUN -eq '1') {
    Write-Host ("[dry-run] would append item to: {0}" -f $Backlog)
    Write-Host ("  title={0}  priority={1}  size={2}  status={3}" -f ($(if ($Title){$Title}else{'<missing>'})), $Priority, $Size, $Status)
    exit 0
}

if (-not (Confirm-BeforeWrite -Message "Append backlog item to $Backlog.")) {
    Write-Error 'Aborted.'; exit 1
}

New-Item -ItemType Directory -Force -Path $Dir | Out-Null

if (-not (Test-Path -LiteralPath $Backlog)) {
    $tpl = Join-Path $SkillDir 'templates\backlog-template.md'
    $c = Get-Content -LiteralPath $tpl -Raw
    $c = $c.Replace('{date}', (Get-Date -Format 'yyyy-MM-dd'))
    # strip placeholder row
    $lines = ($c -split "`n") | Where-Object { $_ -notmatch '^\| BL-01 \|' }
    Set-Content -LiteralPath $Backlog -Value ($lines -join "`n")
}

$next = 1
$existing = Select-String -LiteralPath $Backlog -Pattern '^\| BL-(\d+)' -AllMatches -ErrorAction SilentlyContinue |
    ForEach-Object { $_.Matches } | ForEach-Object { [int]$_.Groups[1].Value }
if ($existing) { $next = ($existing | Measure-Object -Maximum).Maximum + 1 }
$blid = '{0}-{1:D2}' -f 'BL', $next

$row = '| {0} | {1} | {2} | {3} | {4} | {5} |' -f $blid, $Priority, $(if ($Title){$Title}else{'<TBD>'}), $Size, $Status, $(if ($StoryRef){$StoryRef}else{'<none>'})
Add-Content -LiteralPath $Backlog -Value $row

$text = Get-Content -LiteralPath $Backlog -Raw
$total = ([regex]::Matches($text, '(?m)^\| BL-\d+')).Count
Write-Extract -ArtefactPath $Backlog "TOTAL_ITEMS=$total" "LAST_ADDED=$blid" | Out-Null
Write-Host ("Appended {0} to {1}" -f $blid, $Backlog)

if (-not $Title)    { Append-Debt -File $Debts -Prefix 'PODEBT' -Body "Backlog item $blid has no title" | Out-Null }
if (-not $StoryRef) { Append-Debt -File $Debts -Prefix 'PODEBT' -Body "Backlog item $blid has no spec reference (Area: Traceability)" | Out-Null }
