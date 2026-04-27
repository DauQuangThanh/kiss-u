#!/usr/bin/env pwsh
# Scaffold a Vue 3 SPA mockup (Vite + TypeScript + Tailwind CSS v4 +
# PrimeVue + Vue Router v4 + Pinia) into a target directory.
#
# PowerShell parity of scaffold-vue-spa.sh.

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
Usage: scaffold-vue-spa.ps1 [-Auto] [-Answers FILE] [-DryRun] [-Help]

Scaffolds a Vue 3 SPA mockup (Vite + TypeScript + Tailwind CSS v4 +
PrimeVue + Vue Router v4 + Pinia).

Parameters:
  -Auto             Non-interactive; resolve answers from env/answers/extracts/defaults
  -Answers FILE     KEY=VALUE file consulted when -Auto
  -DryRun           Print what would be written, do not touch the filesystem
  -Help             Show this message and exit

Answer keys:
  KISS_VUE_SPA_OUTPUT_DIR   Output directory                        (default: mockup)
  KISS_VUE_SPA_APP_NAME     npm package name                        (default: feature slug or my-app)
  KISS_VUE_SPA_VIEWS        Comma-separated view names              (default: Home)
  KISS_VUE_SPA_THEME        Initial theme: system | light | dark    (default: system)
  KISS_VUE_SPA_LOCALES      Comma-separated BCP-47 locale codes     (default: en,vi)
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

$OutputDir   = Resolve-Auto -Key 'KISS_VUE_SPA_OUTPUT_DIR' -Default 'mockup'
if ($OutputDir -eq 'mockup') {
    Write-Decision -Kind 'default-applied' -What 'KISS_VUE_SPA_OUTPUT_DIR=mockup' -Why 'No output directory specified' | Out-Null
}

$AppName = Resolve-Auto -Key 'KISS_VUE_SPA_APP_NAME' -Default $defaultApp
if ($AppName -eq $defaultApp) {
    Write-Decision -Kind 'default-applied' -What "KISS_VUE_SPA_APP_NAME=$defaultApp" -Why 'No app name specified' | Out-Null
}

$ViewsRaw = Resolve-Auto -Key 'KISS_VUE_SPA_VIEWS' -Default 'Home'
if ($ViewsRaw -eq 'Home') {
    Write-Decision -Kind 'default-applied' -What 'KISS_VUE_SPA_VIEWS=Home' -Why 'No views specified' | Out-Null
}

$ThemeRaw = Resolve-Auto -Key 'KISS_VUE_SPA_THEME' -Default 'system'
$Theme = switch ($ThemeRaw.ToLower()) {
    'light'  { 'light' }
    'dark'   { 'dark' }
    default  { 'system' }
}
if ($ThemeRaw -eq 'system') {
    Write-Decision -Kind 'default-applied' -What 'KISS_VUE_SPA_THEME=system' -Why 'No theme preference specified' | Out-Null
}

$LocalesRaw = Resolve-Auto -Key 'KISS_VUE_SPA_LOCALES' -Default 'en,vi'
if ($LocalesRaw -eq 'en,vi') {
    Write-Decision -Kind 'default-applied' -What 'KISS_VUE_SPA_LOCALES=en,vi' -Why 'No locales specified' | Out-Null
}
$Locales = $LocalesRaw -split ',' | ForEach-Object { $_.Trim().ToLower() } | Where-Object { $_ }
if ('en' -notin $Locales) { $Locales = @('en') + $Locales }
if ('vi' -notin $Locales) { $Locales = $Locales + @('vi') }

$OutRoot = Join-Path $ctx.REPO_ROOT $OutputDir
$DateNow = Get-Date -Format 'yyyy-MM-dd'
$Views   = $ViewsRaw -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }

# ---------------------------------------------------------------------------
# Dry-run output
# ---------------------------------------------------------------------------

if ($env:KISS_DRY_RUN -eq '1') {
    Write-Host "[dry-run] output directory:  $OutRoot"
    Write-Host "[dry-run] app name:          $AppName"
    Write-Host "[dry-run] views:             $($Views -join ', ')"
    Write-Host "[dry-run] theme:             $Theme"
    Write-Host "[dry-run] locales:           $($Locales -join ', ')"
    Write-Host '[dry-run] files that would be written:'
    foreach ($f in @('.gitignore','index.html','package.json','tsconfig.json',
                     'tsconfig.app.json','tsconfig.node.json','vite.config.ts',
                     'src/assets/main.css','src/main.ts','src/App.vue',
                     'src/router/index.ts','src/stores/app.ts','src/i18n/index.ts')) {
        Write-Host ("  {0}" -f (Join-Path $OutRoot $f))
    }
    foreach ($locale in $Locales) {
        Write-Host ("  {0}" -f (Join-Path $OutRoot "src\locales\$locale.json"))
    }
    foreach ($view in $Views) {
        Write-Host ("  {0}" -f (Join-Path $OutRoot "src\views\${view}View.vue"))
    }
    exit 0
}

# ---------------------------------------------------------------------------
# Confirm before write
# ---------------------------------------------------------------------------

if (-not (Confirm-BeforeWrite -Message "Scaffold Vue 3 SPA mockup into $OutRoot.")) {
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
# Build router imports + routes, and App nav links
# ---------------------------------------------------------------------------

$RouterImports = ''
$RouterRoutes  = ''
foreach ($view in $Views) {
    $lower = $view.ToLower()
    $RouterImports += "import ${view}View from '@/views/${view}View.vue'`n"
    if ($view -eq 'Home') {
        $RouterRoutes += "  { path: '/', name: 'home', component: HomeView },`n"
    } else {
        $RouterRoutes += "  { path: '/$lower', name: '$lower', component: ${view}View },`n"
    }
}

$AppNavLinks = ''
if ($Views.Count -gt 1) {
    foreach ($view in $Views) {
        $lower = $view.ToLower()
        $routeName = if ($view -eq 'Home') { 'home' } else { $lower }
        $AppNavLinks += "        <RouterLink :to=`"{ name: '$routeName' }`" active-class=`"font-semibold text-primary`" class=`"text-muted-foreground hover:text-foreground transition-colors`">$view</RouterLink>`n"
    }
}

# ---------------------------------------------------------------------------
# Scaffold files
# ---------------------------------------------------------------------------

Write-Host "Scaffolding $OutRoot ..."
foreach ($d in @('src\assets','src\i18n','src\locales','src\views','src\router','src\stores')) {
    New-Item -ItemType Directory -Force -Path (Join-Path $OutRoot $d) | Out-Null
}

Write-Tpl (Join-Path $OutRoot '.gitignore')             (Expand-Tpl 'gitignore.tpl')
Write-Tpl (Join-Path $OutRoot 'index.html')             (Expand-Tpl 'index.html.tpl')
Write-Tpl (Join-Path $OutRoot 'package.json')           (Expand-Tpl 'package.json.tpl')
Write-Tpl (Join-Path $OutRoot 'tsconfig.json')          (Expand-Tpl 'tsconfig.json.tpl')
Write-Tpl (Join-Path $OutRoot 'tsconfig.app.json')      (Expand-Tpl 'tsconfig.app.json.tpl')
Write-Tpl (Join-Path $OutRoot 'tsconfig.node.json')     (Expand-Tpl 'tsconfig.node.json.tpl')
Write-Tpl (Join-Path $OutRoot 'vite.config.ts')         (Expand-Tpl 'vite.config.ts.tpl')
Write-Tpl (Join-Path $OutRoot 'src\assets\main.css')    (Expand-Tpl 'src-main.css.tpl')
Write-Tpl (Join-Path $OutRoot 'src\main.ts')            (Expand-Tpl 'src-main.ts.tpl')
Write-Tpl (Join-Path $OutRoot 'src\stores\app.ts')      (Expand-Tpl 'src-stores-app.ts.tpl')
Write-Tpl (Join-Path $OutRoot 'src\i18n\index.ts')      (Expand-Tpl 'src-i18n-index.ts.tpl')

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

$appContent = (Expand-Tpl 'src-App.vue.tpl') -replace '\{nav_links\}', $AppNavLinks
Write-Tpl (Join-Path $OutRoot 'src\App.vue') $appContent

$routerContent = (Expand-Tpl 'src-router-index.ts.tpl') `
    -replace '\{router_imports\}', $RouterImports `
    -replace '\{router_routes\}',  $RouterRoutes
Write-Tpl (Join-Path $OutRoot 'src\router\index.ts') $routerContent

$viewTpl = Expand-Tpl 'src-views-View.vue.tpl'
foreach ($view in $Views) {
    $viewContent = $viewTpl -replace '\{view_name\}', $view
    Write-Tpl (Join-Path $OutRoot "src\views\${view}View.vue") $viewContent
}

# ---------------------------------------------------------------------------
# Write .extract and debt entries
# ---------------------------------------------------------------------------

$ExtractFile = Join-Path $OutRoot 'vue-spa-mockup.extract'
Write-Extract -ArtefactPath $ExtractFile `
    "KISS_VUE_SPA_OUTPUT_DIR=$OutputDir" `
    "KISS_VUE_SPA_APP_NAME=$AppName" `
    "KISS_VUE_SPA_VIEWS=$ViewsRaw" `
    "KISS_VUE_SPA_THEME=$Theme" `
    "KISS_VUE_SPA_LOCALES=$LocalesRaw" | Out-Null

$DebtsFile = Join-Path (Join-Path $ctx.REPO_ROOT $ctx.DOCS_DIR) 'design\vue-spa-debts.md'
foreach ($view in $Views) {
    Append-Debt -File $DebtsFile -Prefix 'VUEDEV' `
        -Body "View ${view}View only has placeholder content — replace with real UI" | Out-Null
}

Write-Host ''
Write-Host 'Done. Next steps:'
Write-Host "  cd $OutputDir"
Write-Host '  npm install'
Write-Host '  npm run dev'
