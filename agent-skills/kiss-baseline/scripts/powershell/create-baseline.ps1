#!/usr/bin/env pwsh
param([switch]$Auto, [switch]$DryRun, [string]$Answers, [switch]$Help)
$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $PSCommandPath
. (Join-Path $ScriptDir 'common.ps1')
if ($Auto)    { $env:KISS_AUTO = '1' }
if ($DryRun)  { $env:KISS_DRY_RUN = '1' }
if ($Answers) { $env:KISS_ANSWERS = $Answers; Import-KissAnswers -Path $Answers }
if ($Help) {
    @'
Usage: create-baseline.ps1 [-Auto] [-Answers FILE] [-DryRun] [-Help]

Snapshots artefacts as a named baseline under docs/baselines/<label>/.

Answer keys: BASELINE_TYPE, BASELINE_LABEL, BASELINE_GIT_TAG_AUTO,
             BASELINE_EXTRA_FILES.
Valid types: requirements | design | test | release | custom
'@ | Write-Host; exit 0
}

$ctx      = Read-Context
$SkillDir = (Resolve-Path -LiteralPath (Join-Path $ScriptDir '../..')).Path
$Date     = Get-Date -Format 'yyyy-MM-dd'

$BType   = Resolve-Auto -Key 'BASELINE_TYPE'         -Default ''
$validTypes = @('requirements','design','test','release','custom')
if ([string]::IsNullOrEmpty($BType)) {
    Write-Error "BASELINE_TYPE is required. Valid: $($validTypes -join ' | ')"
    exit 2
}
if ($BType -notin $validTypes) {
    Write-Error "Unknown BASELINE_TYPE '$BType'."; exit 2
}

$Label       = Resolve-Auto -Key 'BASELINE_LABEL'         -Default "$BType-v$Date"
$GitTagAuto  = Resolve-Auto -Key 'BASELINE_GIT_TAG_AUTO'  -Default 'false'
$ExtraFiles  = Resolve-Auto -Key 'BASELINE_EXTRA_FILES'   -Default ''

$BaselineDir   = Join-Path (Join-Path (Join-Path $ctx.REPO_ROOT $ctx.DOCS_DIR) 'baselines') $Label
$ArtefactsDir  = Join-Path $BaselineDir 'artefacts'
$ManifestOut   = Join-Path $BaselineDir 'manifest.md'
$Debts         = Join-Path $BaselineDir 'baseline-debts.md'

if ($env:KISS_DRY_RUN -eq '1') {
    Write-Host ("[dry-run] would create baseline: {0}" -f $BaselineDir)
    Write-Host ("  type={0}  label={1}" -f $BType, $Label)
    exit 0
}

if (Test-Path -LiteralPath $BaselineDir) {
    Write-Error "Baseline '$Label' already exists. Choose a different label."
    exit 2
}

if (-not (Confirm-BeforeWrite -Message "Create baseline '$Label' at $BaselineDir.")) {
    Write-Error 'Aborted.'; exit 1
}

New-Item -ItemType Directory -Force -Path $ArtefactsDir | Out-Null

$DocsRoot  = Join-Path $ctx.REPO_ROOT $ctx.DOCS_DIR
$SpecsRoot = Join-Path $ctx.REPO_ROOT $ctx.SPECS_DIR
$FileList  = @()

switch ($BType) {
    'requirements' {
        $srs = Join-Path $DocsRoot 'architecture\srs.md'
        if (Test-Path -LiteralPath $srs) { $FileList += $srs }
        $FileList += (Get-ChildItem -LiteralPath $SpecsRoot -Recurse -Filter 'spec.md' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName)
    }
    'design' {
        $srs = Join-Path $DocsRoot 'architecture\srs.md'
        if (Test-Path -LiteralPath $srs) { $FileList += $srs }
        $FileList += (Get-ChildItem -Path (Join-Path $DocsRoot 'design') -Recurse -Filter '*.md' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName)
        $FileList += (Get-ChildItem -Path (Join-Path $DocsRoot 'decisions') -Recurse -Filter '*.md' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName)
    }
    'test' {
        $FileList += (Get-ChildItem -Path (Join-Path $DocsRoot 'testing') -Recurse -Filter '*.md' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName)
    }
    'release' {
        $FileList += (Get-ChildItem -Path (Join-Path $DocsRoot 'architecture') -Recurse -Filter '*.md' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName)
        $FileList += (Get-ChildItem -Path (Join-Path $DocsRoot 'design') -Recurse -Filter '*.md' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName)
        $FileList += (Get-ChildItem -Path (Join-Path $DocsRoot 'testing') -Recurse -Filter '*.md' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName)
    }
}

if ($ExtraFiles) {
    foreach ($ef in $ExtraFiles -split ':') {
        $full = Join-Path $ctx.REPO_ROOT $ef
        if (Test-Path -LiteralPath $full) { $FileList += $full }
    }
}

$gitBranch = (git -C $ctx.REPO_ROOT rev-parse --abbrev-ref HEAD 2>$null) ?? 'unknown'
$gitSha    = (git -C $ctx.REPO_ROOT rev-parse HEAD 2>$null) ?? 'unknown'
$rows = ''

foreach ($src in $FileList) {
    if (-not (Test-Path -LiteralPath $src)) {
        Append-Debt -File $Debts -Prefix 'BASEDEBT' -Body "File not found: $src" | Out-Null
        continue
    }
    $rel = $src.Replace($ctx.REPO_ROOT + [System.IO.Path]::DirectorySeparatorChar, '').Replace('\','/')
    $dst = Join-Path $ArtefactsDir ($rel.Replace('/', '\'))
    New-Item -ItemType Directory -Force -Path (Split-Path $dst -Parent) | Out-Null
    Copy-Item -LiteralPath $src -Destination $dst -Force
    $sha = (Get-FileHash -LiteralPath $src -Algorithm SHA256).Hash.ToLower()
    $sz  = (Get-Item -LiteralPath $src).Length
    $rows += "| $rel | artefacts/$rel | ``$($sha.Substring(0,16))…`` | ${sz}B |`n"
}

$tpl = Get-Content -LiteralPath (Join-Path $SkillDir 'templates\manifest-template.md') -Raw
$tpl = $tpl.Replace('{label}', $Label).Replace('{type}', $BType).Replace('{date}', $Date)
$tpl = $tpl.Replace('{file_count}', $FileList.Count).Replace('{git_branch}', $gitBranch)
$tpl = $tpl.Replace('{git_sha}', $gitSha.Substring(0, [Math]::Min(12, $gitSha.Length)))
$tpl = $tpl.Replace('{rows}', $rows.TrimEnd())
Set-Content -LiteralPath $ManifestOut -Value $tpl

Write-Extract -ArtefactPath $ManifestOut `
    "BASELINE_LABEL=$Label" `
    "BASELINE_TYPE=$BType" `
    "BASELINE_DATE=$Date" `
    "GIT_TAG=baseline/$Label" `
    "GIT_SHA=$gitSha" `
    "FILE_COUNT=$($FileList.Count)" | Out-Null

Write-Host ("Wrote baseline manifest: {0}" -f $ManifestOut)
Write-Host ("Files copied: {0}" -f $FileList.Count)

if ($GitTagAuto -eq 'true') {
    try {
        git -C $ctx.REPO_ROOT tag -a "baseline/$Label" -m "Baseline $Label — $BType phase" 2>$null
        Write-Host "Git tag created: baseline/$Label"
    } catch {
        Write-Warning "Could not create git tag. Run manually: git tag -a baseline/$Label"
    }
} else {
    Write-Host ""
    Write-Host "To tag this baseline in git, run:"
    Write-Host "  git tag -a baseline/$Label -m `"Baseline $Label — $BType phase`""
    Write-Host "  git push origin baseline/$Label"
}
