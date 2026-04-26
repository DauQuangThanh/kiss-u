#!/usr/bin/env pwsh
# kiss-standardize PowerShell parity of update-standards.sh.

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
if ($Answers) {
    $env:KISS_ANSWERS = $Answers
    Import-KissAnswers -Path $Answers
}

if ($Help) {
    @'
Usage: update-standards.ps1 [-Auto] [-Answers FILE] [-DryRun] [-Help]

Initialises docs/standards.md from the skill template when it does not
exist yet, or verifies it is present so the AI prompt can proceed with
filling/updating the placeholder tokens.

Exit codes:
  0  — file already exists (update mode) or was scaffolded (init mode)
  1  — aborted by user / missing template
'@ | Write-Host
    exit 0
}

$ctx        = Read-Context
$SkillDir   = (Resolve-Path -LiteralPath (Join-Path $ScriptDir '..\..')).Path
$DocsDir    = Join-Path $ctx.REPO_ROOT $ctx.DOCS_DIR
$StandardsFile = Join-Path $DocsDir 'standards.md'
$Template   = Join-Path $SkillDir 'templates\standard-template.md'
$DebtsFile  = Join-Path $DocsDir 'pm-debts.md'

$Today       = Get-Date -Format 'yyyy-MM-dd'
$ProjectName = Resolve-Auto -Key 'STANDARDS_PROJECT_NAME' -Default ''

if ($env:KISS_DRY_RUN -eq '1') {
    if (Test-Path -LiteralPath $StandardsFile) {
        Write-Host ("[dry-run] standards.md exists — would update: {0}" -f $StandardsFile)
    } else {
        Write-Host ("[dry-run] standards.md not found — would scaffold from template: {0}" -f $StandardsFile)
        Write-Host ("[dry-run] template: {0}" -f $Template)
    }
    Write-Host ("[dry-run] project_name: {0}" -f $(if ($ProjectName) { $ProjectName } else { '<derived at AI-prompt time>' }))
    exit 0
}

if (-not (Test-Path -LiteralPath $Template)) {
    Write-Error ("Template not found: {0}" -f $Template)
    exit 1
}

if (Test-Path -LiteralPath $StandardsFile) {
    # File already exists — the AI prompt will perform the update in-place.
    Write-Host ("standards.md already exists: {0}" -f $StandardsFile)
    Write-Host 'MODE=update'
    exit 0
}

# --- First-time initialisation ---
if (-not (Confirm-BeforeWrite -Message "Scaffold standards.md at $StandardsFile from template.")) {
    Write-Error 'Aborted.'
    exit 1
}

New-Item -ItemType Directory -Force -Path $DocsDir | Out-Null

# Resolve project name: try env var, then git remote, then repo folder name.
if (-not $ProjectName) {
    try {
        $remote = git -C $ctx.REPO_ROOT remote get-url origin 2>$null
        if ($LASTEXITCODE -eq 0 -and $remote) {
            $ProjectName = ($remote -replace '^.*[/:]', '') -replace '\.git$', ''
        }
    } catch {}
}
if (-not $ProjectName) {
    $ProjectName = Split-Path $ctx.REPO_ROOT -Leaf
}

$content = Get-Content -LiteralPath $Template -Raw
$content = $content.Replace('[PROJECT_NAME]',      $ProjectName)
$content = $content.Replace('[RATIFICATION_DATE]', $Today)
$content = $content.Replace('[LAST_AMENDED_DATE]', $Today)
$content = $content.Replace('[STANDARDS_VERSION]', '1.0.0')
Set-Content -LiteralPath $StandardsFile -Value $content

Write-Extract -ArtefactPath $StandardsFile `
    "PROJECT_NAME=$ProjectName" `
    "STANDARDS_VERSION=1.0.0" `
    "RATIFICATION_DATE=$Today" `
    "LAST_AMENDED_DATE=$Today" | Out-Null

Write-Host ("Scaffolded {0}" -f $StandardsFile)
Write-Host 'MODE=init'

# Record a debt so the user knows they still need to fill placeholders.
Append-Debt -File $DebtsFile -Prefix 'PMDEBT' `
    -Body "standards.md was scaffolded on $Today with placeholder tokens — replace all [UPPER_CASE] tokens (Area: Standards, Priority: 🔴 Urgent)" | Out-Null
