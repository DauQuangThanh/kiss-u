#!/usr/bin/env pwsh
param([switch]$Auto, [switch]$DryRun, [string]$Answers, [switch]$Help)
$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $PSCommandPath
. (Join-Path $ScriptDir 'common.ps1')
if ($Auto)    { $env:KISS_AUTO = '1' }
if ($DryRun)  { $env:KISS_DRY_RUN = '1' }
if ($Answers) { $env:KISS_ANSWERS = $Answers; Import-KissAnswers -Path $Answers }
if ($Help) { "Usage: scaffold-tests.ps1 -Auto. Keys: UT_FRAMEWORK, UT_TARGET_DIR, UT_MIN_COVERAGE." | Write-Host; exit 0 }

$ctx = Read-Context
if (-not $ctx.CURRENT_FEATURE) { Write-Error "current.feature required"; exit 2 }
$SkillDir = (Resolve-Path -LiteralPath (Join-Path $ScriptDir '..\..')).Path
$Dir   = Get-FeatureScopedDir -Name 'testing'
$Debts = Join-Path $Dir 'test-debts.md'

$fw = ''; $tgt = ''
$root = $ctx.REPO_ROOT
if ((Test-Path (Join-Path $root 'pyproject.toml')) -or (Test-Path (Join-Path $root 'pytest.ini'))) {
    $fw = 'pytest'; $tgt = 'tests'
} elseif (Test-Path (Join-Path $root 'package.json')) {
    $pkg = Get-Content -LiteralPath (Join-Path $root 'package.json') -Raw
    if ($pkg -match '"vitest"')      { $fw = 'vitest';  $tgt = 'tests' }
    elseif ($pkg -match '"jest"')    { $fw = 'jest';    $tgt = '__tests__' }
    elseif ($pkg -match '"mocha"')   { $fw = 'mocha';   $tgt = 'test' }
} elseif (Test-Path (Join-Path $root 'go.mod')) { $fw = 'go-test'; $tgt = '(co-located)' }
elseif (Test-Path (Join-Path $root 'Cargo.toml')) { $fw = 'cargo-test'; $tgt = 'tests' }
elseif (Get-ChildItem -Path $root -Filter '*.csproj' -ErrorAction SilentlyContinue) { $fw = 'xunit'; $tgt = '<proj>.Tests' }
elseif (Test-Path (Join-Path $root 'pom.xml')) { $fw = 'junit5'; $tgt = 'src/test/java' }
elseif (Test-Path (Join-Path $root 'Gemfile')) { $fw = 'rspec'; $tgt = 'spec' }
elseif (Test-Path (Join-Path $root 'mix.exs')) { $fw = 'exunit'; $tgt = 'test' }

$Framework  = Resolve-Auto -Key 'UT_FRAMEWORK'     -Default $(if ($fw) { $fw } else { 'unknown' })
$TargetDir  = Resolve-Auto -Key 'UT_TARGET_DIR'    -Default $(if ($tgt) { $tgt } else { 'tests' })
$Cov        = Resolve-Auto -Key 'UT_MIN_COVERAGE'  -Default '80'

$Out = Join-Path $Dir 'unit-tests-index.md'

if ($env:KISS_DRY_RUN -eq '1') { Write-Host ("[dry-run] would write: {0}  framework={1}" -f $Out, $Framework); exit 0 }
if (-not (Confirm-BeforeWrite -Message "Scaffold unit-tests index at $Out.")) { Write-Error 'Aborted.'; exit 1 }
if (Test-Path -LiteralPath $Out) { Write-Error "Index exists: $Out"; exit 2 }

$tpl = Join-Path $SkillDir 'templates\unit-tests-index-template.md'
$c = Get-Content -LiteralPath $tpl -Raw
$c = $c.Replace('{feature}', $ctx.CURRENT_FEATURE).Replace('{date}', (Get-Date -Format 'yyyy-MM-dd'))
$c = $c.Replace('{framework}', $Framework).Replace('{target_dir}', $TargetDir).Replace('{min_coverage}', $Cov)
Set-Content -LiteralPath $Out -Value $c

Write-Extract -ArtefactPath $Out "FEATURE=$($ctx.CURRENT_FEATURE)" "FRAMEWORK=$Framework" "TARGET_DIR=$TargetDir" "MIN_COVERAGE=$Cov" | Out-Null
Write-Host ("Wrote {0}" -f $Out)

if ($Framework -eq 'unknown') {
    Append-Debt -File $Debts -Prefix 'TQDEBT' -Body "Unit-test framework could not be detected" | Out-Null
}
