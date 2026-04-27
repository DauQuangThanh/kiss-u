#!/usr/bin/env pwsh
# Scaffold a React SPA mockup (Vite + TypeScript + Tailwind CSS v4 +
# shadcn/ui + React Router v7) into a target directory.
#
# PowerShell parity of scaffold-spa.sh.

param(
    [switch]$Auto,
    [switch]$DryRun,
    [string]$Answers,
    [switch]$Help
)

$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $PSCommandPath
. (Join-Path $ScriptDir 'common.ps1')

if ($Auto)    { $env:KISS_AUTO    = '1' }
if ($DryRun)  { $env:KISS_DRY_RUN = '1' }
if ($Answers) {
    $env:KISS_ANSWERS = $Answers
    Import-KissAnswers -Path $Answers
}

if ($Help) {
    @'
Usage: scaffold-spa.ps1 [-Auto] [-Answers FILE] [-DryRun] [-Help]

Scaffolds a React SPA mockup (Vite + TypeScript + Tailwind CSS v4 +
shadcn/ui + React Router v7).

Parameters:
  -Auto             Non-interactive; resolve answers from env/answers/extracts/defaults
  -Answers FILE     KEY=VALUE file consulted when -Auto
  -DryRun           Print what would be written, do not touch the filesystem
  -Help             Show this message and exit

Answer keys:
  KISS_SPA_OUTPUT_DIR   Output directory                        (default: mockup)
  KISS_SPA_APP_NAME     npm package name                        (default: feature slug or my-app)
  KISS_SPA_PAGES        Comma-separated page names              (default: Home)
  KISS_SPA_THEME        Initial theme: system | light | dark    (default: system)
  KISS_SPA_LOCALES      Comma-separated BCP-47 locale codes     (default: en,vi)
'@ | Write-Host
    exit 0
}

$ctx = Read-Context
$SkillDir = (Resolve-Path -LiteralPath (Join-Path $ScriptDir '..\..')).Path

# ---------------------------------------------------------------------------
# Resolve answer keys
# ---------------------------------------------------------------------------

$defaultSlug = if ($ctx.CURRENT_FEATURE) { $ctx.CURRENT_FEATURE } else { 'my-app' }
$defaultApp  = $defaultSlug.ToLower() -replace '[\s_/]+', '-'

$OutputDir = Resolve-Auto -Key 'KISS_SPA_OUTPUT_DIR' -Default 'mockup'
if ($OutputDir -eq 'mockup') {
    Write-Decision -Kind 'default-applied' -What 'KISS_SPA_OUTPUT_DIR=mockup' -Why 'No output directory specified' | Out-Null
}

$AppName = Resolve-Auto -Key 'KISS_SPA_APP_NAME' -Default $defaultApp
if ($AppName -eq $defaultApp) {
    Write-Decision -Kind 'default-applied' -What "KISS_SPA_APP_NAME=$defaultApp" -Why 'No app name specified' | Out-Null
}

$PagesRaw = Resolve-Auto -Key 'KISS_SPA_PAGES' -Default 'Home'
if ($PagesRaw -eq 'Home') {
    Write-Decision -Kind 'default-applied' -What 'KISS_SPA_PAGES=Home' -Why 'No pages specified' | Out-Null
}

$ThemeRaw = Resolve-Auto -Key 'KISS_SPA_THEME' -Default 'system'
$Theme = switch ($ThemeRaw.ToLower()) {
    'light'  { 'light' }
    'dark'   { 'dark' }
    default  { 'system' }
}
if ($ThemeRaw -eq 'system') {
    Write-Decision -Kind 'default-applied' -What 'KISS_SPA_THEME=system' -Why 'No theme preference specified' | Out-Null
}

$LocalesRaw = Resolve-Auto -Key 'KISS_SPA_LOCALES' -Default 'en,vi'
if ($LocalesRaw -eq 'en,vi') {
    Write-Decision -Kind 'default-applied' -What 'KISS_SPA_LOCALES=en,vi' -Why 'No locales specified' | Out-Null
}
$Locales = $LocalesRaw -split ',' | ForEach-Object { $_.Trim().ToLower() } | Where-Object { $_ }
if ('en' -notin $Locales) { $Locales = @('en') + $Locales }
if ('vi' -notin $Locales) { $Locales = $Locales + @('vi') }

$OutRoot  = Join-Path $ctx.REPO_ROOT $OutputDir
$DateNow  = Get-Date -Format 'yyyy-MM-dd'
$Pages    = $PagesRaw -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }

# ---------------------------------------------------------------------------
# Dry-run output
# ---------------------------------------------------------------------------

if ($env:KISS_DRY_RUN -eq '1') {
    Write-Host "[dry-run] output directory:  $OutRoot"
    Write-Host "[dry-run] app name:          $AppName"
    Write-Host "[dry-run] pages:             $($Pages -join ', ')"
    Write-Host "[dry-run] theme:             $Theme"
    Write-Host "[dry-run] locales:           $($Locales -join ', ')"
    Write-Host '[dry-run] files that would be written:'
    foreach ($f in @('.gitignore','components.json','index.html','package.json',
                     'tsconfig.json','tsconfig.app.json','vite.config.ts',
                     'src/index.css','src/main.tsx','src/App.tsx',
                     'src/router.tsx','src/hooks/useTheme.ts',
                     'src/i18n/setup.ts','src/lib/utils.ts')) {
        Write-Host ("  {0}" -f (Join-Path $OutRoot $f))
    }
    foreach ($locale in $Locales) {
        Write-Host ("  {0}" -f (Join-Path $OutRoot "src\locales\$locale.json"))
    }
    foreach ($page in $Pages) {
        Write-Host "  $(Join-Path $OutRoot "src\pages\$page.tsx")"
    }
    exit 0
}

# ---------------------------------------------------------------------------
# Confirm before write
# ---------------------------------------------------------------------------

if (-not (Confirm-BeforeWrite -Message "Scaffold React SPA mockup into $OutRoot.")) {
    Write-Error 'Aborted.'
    exit 1
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

function Expand-Tpl {
    param([string]$Name)
    $tplPath = Join-Path $SkillDir "templates\$Name"
    if (-not (Test-Path -LiteralPath $tplPath)) {
        throw "Template not found: $tplPath"
    }
    (Get-Content -LiteralPath $tplPath -Raw) `
        -replace '\{app_name\}', $AppName `
        -replace '\{date\}',     $DateNow `
        -replace '\{output_dir\}',$OutputDir `
        -replace '\{theme\}',    $Theme
}

function Write-Tpl {
    param([string]$Dest, [string]$Content)
    $dir = Split-Path $Dest -Parent
    if (-not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }
    Set-Content -LiteralPath $Dest -Value $Content
    Write-Host ("  wrote {0}" -f $Dest)
}

# ---------------------------------------------------------------------------
# Build router + App content from page list
# ---------------------------------------------------------------------------

$RouterImports = ''
$RouterRoutes  = ''
foreach ($page in $Pages) {
    $RouterImports += "import $page from './pages/$page';" + "`n"
    $path = if ($page -eq 'Home') { '/' } else { '/' + $page.ToLower() }
    $RouterRoutes  += "  { path: '$path', element: <$page /> }," + "`n"
}

$AppNavLinks = ''
if ($Pages.Count -gt 1) {
    foreach ($page in $Pages) {
        $path = if ($page -eq 'Home') { '/' } else { '/' + $page.ToLower() }
        $AppNavLinks += "          <NavLink to=`"$path`" className={({ isActive }) => isActive ? 'font-semibold text-primary' : 'text-muted-foreground hover:text-foreground transition-colors'}>$page</NavLink>`n"
    }
}

# ---------------------------------------------------------------------------
# Scaffold files
# ---------------------------------------------------------------------------

Write-Host "Scaffolding $OutRoot ..."
foreach ($d in @('src\hooks','src\i18n','src\lib','src\locales','src\pages')) {
    New-Item -ItemType Directory -Force -Path (Join-Path $OutRoot $d) | Out-Null
}

Write-Tpl (Join-Path $OutRoot '.gitignore')         (Expand-Tpl 'gitignore.tpl')
Write-Tpl (Join-Path $OutRoot 'components.json')    (Expand-Tpl 'components.json.tpl')
Write-Tpl (Join-Path $OutRoot 'index.html')         (Expand-Tpl 'index.html.tpl')
Write-Tpl (Join-Path $OutRoot 'package.json')       (Expand-Tpl 'package.json.tpl')
Write-Tpl (Join-Path $OutRoot 'tsconfig.json')      (Expand-Tpl 'tsconfig.json.tpl')
Write-Tpl (Join-Path $OutRoot 'tsconfig.app.json')  (Expand-Tpl 'tsconfig.app.json.tpl')
Write-Tpl (Join-Path $OutRoot 'vite.config.ts')     (Expand-Tpl 'vite.config.ts.tpl')
Write-Tpl (Join-Path $OutRoot 'src\index.css')      (Expand-Tpl 'src-index.css.tpl')
Write-Tpl (Join-Path $OutRoot 'src\main.tsx')       (Expand-Tpl 'src-main.tsx.tpl')
Write-Tpl (Join-Path $OutRoot 'src\hooks\useTheme.ts') (Expand-Tpl 'src-hooks-useTheme.ts.tpl')
Write-Tpl (Join-Path $OutRoot 'src\i18n\setup.ts')  (Expand-Tpl 'src-i18n-setup.ts.tpl')
Write-Tpl (Join-Path $OutRoot 'src\lib\utils.ts')   (Expand-Tpl 'src-lib-utils.ts.tpl')

$stubTpl = Expand-Tpl 'src-locales-locale.json.tpl'
foreach ($locale in $Locales) {
    $localeTpl = "src-locales-$locale.json.tpl"
    if (Test-Path -LiteralPath (Join-Path $SkillDir "templates\$localeTpl")) {
        $localeContent = Expand-Tpl $localeTpl
    } else {
        $localeContent = $stubTpl -replace '\{locale\}', $locale
    }
    Write-Tpl (Join-Path $OutRoot "src\locales\$locale.json") $localeContent
}

$appContent = (Expand-Tpl 'src-App.tsx.tpl') -replace '\{nav_links\}', $AppNavLinks
Write-Tpl (Join-Path $OutRoot 'src\App.tsx') $appContent

$routerContent = (Expand-Tpl 'src-router.tsx.tpl') `
    -replace '\{router_imports\}', $RouterImports `
    -replace '\{router_routes\}',  $RouterRoutes
Write-Tpl (Join-Path $OutRoot 'src\router.tsx') $routerContent

$pageTpl = Expand-Tpl 'src-pages-Page.tsx.tpl'
foreach ($page in $Pages) {
    $pageContent = $pageTpl -replace '\{page_name\}', $page
    Write-Tpl (Join-Path $OutRoot "src\pages\$page.tsx") $pageContent
}

# ---------------------------------------------------------------------------
# Write .extract and debt entries
# ---------------------------------------------------------------------------

$ExtractFile = Join-Path $OutRoot 'spa-mockup.extract'
Write-Extract -ArtefactPath $ExtractFile `
    "KISS_SPA_OUTPUT_DIR=$OutputDir" `
    "KISS_SPA_APP_NAME=$AppName" `
    "KISS_SPA_PAGES=$PagesRaw" `
    "KISS_SPA_THEME=$Theme" `
    "KISS_SPA_LOCALES=$LocalesRaw" | Out-Null

$DebtsFile = Join-Path (Join-Path $ctx.REPO_ROOT $ctx.DOCS_DIR) 'design\spa-debts.md'
foreach ($page in $Pages) {
    Append-Debt -File $DebtsFile -Prefix 'SPADEV' `
        -Body "Page $page only has placeholder content — replace with real UI" | Out-Null
}

Write-Host ''
Write-Host 'Done. Next steps:'
Write-Host "  cd $OutputDir"
Write-Host '  npm install'
Write-Host '  npm run dev'
