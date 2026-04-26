#!/usr/bin/env pwsh
# PowerShell parity of scripts/bash/common.sh.
#
# Every role-skill's action scripts dot-source this file to get:
#   - Read-Context             : parse .kiss/context.yml into $script:KissCtx
#   - Get-WorktypeDir <name>   : resolve docs/<work-type>/
#   - Get-FeatureScopedDir <n> : resolve docs/<work-type>/<feature>/
#   - Append-Debt              : append a numbered debt entry
#   - Write-Extract            : write a .extract companion file
#   - Confirm-BeforeWrite      : honour preferences.confirm_before_write
#   - Resolve-Auto <key>       : -Auto / env / answers / .extract lookup

# -------------------------------------------------------------------
# Repo-root discovery.
# -------------------------------------------------------------------

function Find-KissRoot {
    param([string]$StartDir = (Get-Location).Path)
    $resolved = Resolve-Path -LiteralPath $StartDir -ErrorAction SilentlyContinue
    $current = if ($resolved) { $resolved.Path } else { $null }
    if (-not $current) { return $null }

    while ($true) {
        if (Test-Path -LiteralPath (Join-Path $current ".kiss") -PathType Container) {
            return $current
        }
        $parent = Split-Path $current -Parent
        if ([string]::IsNullOrEmpty($parent) -or $parent -eq $current) {
            return $null
        }
        $current = $parent
    }
}

function Get-RepoRoot {
    $kissRoot = Find-KissRoot
    if ($kissRoot) { return $kissRoot }

    try {
        $result = git rev-parse --show-toplevel 2>$null
        if ($LASTEXITCODE -eq 0 -and $result) { return $result }
    } catch {}

    return (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "../../../..")).Path
}

# -------------------------------------------------------------------
# Context-file parsing.
# -------------------------------------------------------------------

$script:KissDefaults = @{
    DOCS_DIR              = 'docs'
    SPECS_DIR             = 'docs/specs'
    PLANS_DIR             = 'docs/plans'
    TASKS_DIR             = 'docs/tasks'
    TEMPLATES_DIR         = 'templates'
    SCRIPTS_DIR           = 'scripts'
    CONFIRM_BEFORE_WRITE  = $true
    OUTPUT_FORMAT         = 'markdown'
}

$script:KissCtxWarned = $false

function Write-KissContextWarning {
    if (-not $script:KissCtxWarned) {
        Write-Warning '[kiss] .kiss/context.yml not found — applying documented defaults'
        $script:KissCtxWarned = $true
    }
}

function _KissParseContextMinimal {
    param([string]$Path)

    $data = @{
        paths       = @{}
        current     = @{}
        preferences = @{}
    }

    $section = $null
    Get-Content -LiteralPath $Path -ErrorAction Stop | ForEach-Object {
        $line = $_.TrimEnd()
        if ([string]::IsNullOrWhiteSpace($line)) { return }
        if ($line.TrimStart().StartsWith('#')) { return }

        if ($line -match '^([a-z_]+):\s*$') {
            $section = $Matches[1]
            if (-not $data.ContainsKey($section)) {
                $data[$section] = @{}
            }
            return
        }

        if ($line -match '^\s+([a-z_]+):\s*(.*)$') {
            $key   = $Matches[1]
            $value = $Matches[2].Trim()

            if ($value.StartsWith('"') -and $value.EndsWith('"')) {
                $value = $value.Substring(1, $value.Length - 2)
            } elseif ($value.StartsWith("'") -and $value.EndsWith("'")) {
                $value = $value.Substring(1, $value.Length - 2)
            }

            if ($value -in @('null', '~', '')) {
                $value = $null
            }

            if ($section -and $data.ContainsKey($section)) {
                $data[$section][$key] = $value
            }
        }
    }

    return $data
}

function Read-Context {
    $repoRoot = Get-RepoRoot
    $contextFile = Join-Path $repoRoot ".kiss/context.yml"

    # Start with defaults
    $script:KissCtx = [pscustomobject]@{
        REPO_ROOT              = $repoRoot
        DOCS_DIR               = $script:KissDefaults.DOCS_DIR
        SPECS_DIR              = $script:KissDefaults.SPECS_DIR
        PLANS_DIR              = $script:KissDefaults.PLANS_DIR
        TASKS_DIR              = $script:KissDefaults.TASKS_DIR
        TEMPLATES_DIR          = $script:KissDefaults.TEMPLATES_DIR
        SCRIPTS_DIR            = $script:KissDefaults.SCRIPTS_DIR
        CURRENT_FEATURE        = $null
        CURRENT_SPEC           = $null
        CURRENT_PLAN           = $null
        CURRENT_TASK           = $null
        CURRENT_CHECKLIST      = $null
        CURRENT_BRANCH         = $null
        CONFIRM_BEFORE_WRITE   = $script:KissDefaults.CONFIRM_BEFORE_WRITE
        OUTPUT_FORMAT          = $script:KissDefaults.OUTPUT_FORMAT
    }

    if (-not (Test-Path -LiteralPath $contextFile)) {
        Write-KissContextWarning
        return $script:KissCtx
    }

    try {
        $parsed = _KissParseContextMinimal -Path $contextFile
    } catch {
        Write-Warning ("[kiss] Failed to parse .kiss/context.yml: {0}" -f $_.Exception.Message)
        return $script:KissCtx
    }

    $paths    = $parsed['paths']
    $current  = $parsed['current']
    $prefs    = $parsed['preferences']

    if ($paths) {
        if ($paths['docs'])      { $script:KissCtx.DOCS_DIR      = $paths['docs'] }
        if ($paths['specs'])     { $script:KissCtx.SPECS_DIR     = $paths['specs'] }
        if ($paths['plans'])     { $script:KissCtx.PLANS_DIR     = $paths['plans'] }
        if ($paths['tasks'])     { $script:KissCtx.TASKS_DIR     = $paths['tasks'] }
        if ($paths['templates']) { $script:KissCtx.TEMPLATES_DIR = $paths['templates'] }
        if ($paths['scripts'])   { $script:KissCtx.SCRIPTS_DIR   = $paths['scripts'] }
    }
    if ($current) {
        $script:KissCtx.CURRENT_FEATURE   = $current['feature']
        $script:KissCtx.CURRENT_SPEC      = $current['spec']
        $script:KissCtx.CURRENT_PLAN      = $current['plan']
        $script:KissCtx.CURRENT_TASK      = $current['task']
        $script:KissCtx.CURRENT_CHECKLIST = $current['checklist']
        $script:KissCtx.CURRENT_BRANCH    = $current['branch']
    }
    if ($prefs) {
        if ($prefs.ContainsKey('confirm_before_write')) {
            $raw = $prefs['confirm_before_write']
            $script:KissCtx.CONFIRM_BEFORE_WRITE = ($raw -eq 'true' -or $raw -eq $true)
        }
        if ($prefs['output_format']) {
            $script:KissCtx.OUTPUT_FORMAT = $prefs['output_format']
        }
    }

    # Agent mode (auto | interactive). When `auto`, enable KISS_AUTO
    # so skill action scripts take non-interactive paths.
    if (-not $env:KISS_AGENT_MODE) { $env:KISS_AGENT_MODE = 'interactive' }
    if ($env:KISS_AGENT_MODE -in @('auto','AUTO','Auto')) {
        $env:KISS_AGENT_MODE = 'auto'
        if (-not $env:KISS_AUTO) { $env:KISS_AUTO = '1' }
    } else {
        $env:KISS_AGENT_MODE = 'interactive'
    }

    return $script:KissCtx
}

# -------------------------------------------------------------------
# Path resolution.
# -------------------------------------------------------------------

function Get-WorktypeDir {
    param([Parameter(Mandatory=$true)][string]$Name)
    if (-not $script:KissCtx) { Read-Context | Out-Null }
    $dir = Join-Path (Join-Path $script:KissCtx.REPO_ROOT $script:KissCtx.DOCS_DIR) $Name
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    return $dir
}

function Get-FeatureScopedDir {
    param([Parameter(Mandatory=$true)][string]$Name)
    if (-not $script:KissCtx) { Read-Context | Out-Null }
    if ([string]::IsNullOrEmpty($script:KissCtx.CURRENT_FEATURE)) {
        throw "Get-FeatureScopedDir: .kiss/context.yml 'current.feature' is not set"
    }
    $dir = Join-Path `
        (Join-Path (Join-Path $script:KissCtx.REPO_ROOT $script:KissCtx.DOCS_DIR) $Name) `
        $script:KissCtx.CURRENT_FEATURE
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    return $dir
}

# -------------------------------------------------------------------
# Agent-decisions log (see common.sh for the full contract).
# -------------------------------------------------------------------

function Write-Decision {
    param(
        [Parameter(Mandatory=$true)][ValidateSet('default-applied','alternative-picked','autonomous-action','debt-overridden')][string]$Kind,
        [Parameter(Mandatory=$true)][string]$What,
        [string]$Why = '',
        [string]$Alternatives = ''
    )

    if (-not $script:KissCtx) { Read-Context | Out-Null }
    $agent = if ($env:KISS_AGENT) { $env:KISS_AGENT } else { 'shared' }
    $dateS = Get-Date -Format 'yyyy-MM-dd'
    $dir = Join-Path (Join-Path (Join-Path $script:KissCtx.REPO_ROOT $script:KissCtx.DOCS_DIR) 'agent-decisions') $agent
    $file = Join-Path $dir ("{0}-decisions.md" -f $dateS)
    New-Item -ItemType Directory -Force -Path $dir | Out-Null

    $next = 1
    if (Test-Path -LiteralPath $file) {
        $matches = Select-String -LiteralPath $file -Pattern '^### D-(\d+)' -AllMatches -ErrorAction SilentlyContinue |
            ForEach-Object { $_.Matches } | ForEach-Object { [int]$_.Groups[1].Value }
        if ($matches) { $next = ($matches | Measure-Object -Maximum).Maximum + 1 }
    } else {
        $header = @"
# Agent decisions — $agent — $dateS

**Mode:** $(if ($env:KISS_AGENT_MODE) { $env:KISS_AGENT_MODE } else { 'interactive' })

"@
        Set-Content -LiteralPath $file -Value $header
    }

    $id = '{0}-{1:D2}' -f 'D', $next
    $iso = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')

    $block = @"
### $id — $Kind

- **What:** $What
"@
    if ($Why) { $block += "`n- **Why:** $Why" }
    if ($Alternatives) { $block += "`n- **Alternatives considered:** $Alternatives" }
    $block += "`n- **Time:** $iso`n"

    Add-Content -LiteralPath $file -Value $block
    return $id
}

# -------------------------------------------------------------------
# Debt register.
# -------------------------------------------------------------------

function Append-Debt {
    param(
        [Parameter(Mandatory=$true)][string]$File,
        [Parameter(Mandatory=$true)][string]$Prefix,
        [Parameter(Mandatory=$true)][string]$Body
    )

    $dir = Split-Path $File -Parent
    if ($dir -and -not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }

    $next = 1
    if (Test-Path -LiteralPath $File) {
        $pattern = "^{0}-(\d+)" -f [regex]::Escape($Prefix)
        $nums = @()
        Get-Content -LiteralPath $File | ForEach-Object {
            if ($_ -match $pattern) { $nums += [int]$Matches[1] }
        }
        if ($nums.Count -gt 0) {
            $next = ($nums | Measure-Object -Maximum).Maximum + 1
        }
    } else {
        Set-Content -LiteralPath $File -Value "# Debt register ($Prefix)`n" -NoNewline
    }

    $id = '{0}-{1:D2}' -f $Prefix, $next
    Add-Content -LiteralPath $File -Value ("{0}: {1}" -f $id, $Body)
    return $id
}

# -------------------------------------------------------------------
# .extract companion files.
# -------------------------------------------------------------------

function Write-Extract {
    param(
        [Parameter(Mandatory=$true)][string]$ArtefactPath,
        [Parameter(ValueFromRemainingArguments=$true)][string[]]$Pairs
    )

    $extract = [System.IO.Path]::ChangeExtension($ArtefactPath, 'extract')
    $dir = Split-Path $extract -Parent
    if ($dir -and -not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }

    Set-Content -LiteralPath $extract -Value "" -NoNewline
    foreach ($pair in $Pairs) {
        Add-Content -LiteralPath $extract -Value $pair
    }
    return $extract
}

# -------------------------------------------------------------------
# Confirm-BeforeWrite.
# -------------------------------------------------------------------

function Confirm-BeforeWrite {
    param([string]$Message = 'About to write.')

    if ($env:KISS_AUTO -eq '1') { return $true }
    if (-not $script:KissCtx) { Read-Context | Out-Null }
    if (-not $script:KissCtx.CONFIRM_BEFORE_WRITE) { return $true }

    $answer = Read-Host -Prompt "$Message  Proceed? [y/N]"
    return ($answer -match '^(y|yes)$')
}

# -------------------------------------------------------------------
# -Auto / env / answers / .extract resolution.
# -------------------------------------------------------------------

function Import-KissAnswers {
    param([Parameter(Mandatory=$true)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return }
    Get-Content -LiteralPath $Path | ForEach-Object {
        $line = $_.Trim()
        if ([string]::IsNullOrWhiteSpace($line)) { return }
        if ($line.StartsWith('#')) { return }
        $eq = $line.IndexOf('=')
        if ($eq -le 0) { return }
        $key = $line.Substring(0, $eq)
        $val = $line.Substring($eq + 1)
        $val = $val.Trim('"').Trim("'")
        if (-not (Test-Path -LiteralPath "env:$key")) {
            Set-Item -LiteralPath "env:$key" -Value $val
        }
    }
}

function Resolve-Auto {
    param(
        [Parameter(Mandatory=$true)][string]$Key,
        [string]$Default = ''
    )

    # 1. env var
    $val = [System.Environment]::GetEnvironmentVariable($Key)
    if ($val) { return $val }

    # 2. answers file
    if ($env:KISS_ANSWERS -and (Test-Path -LiteralPath $env:KISS_ANSWERS)) {
        $match = Get-Content -LiteralPath $env:KISS_ANSWERS |
            Where-Object { $_ -match "^$([regex]::Escape($Key))=" } |
            Select-Object -First 1
        if ($match) { return ($match -replace "^$([regex]::Escape($Key))=", '') }
    }

    # 3. .extract chain
    if ($env:KISS_EXTRACTS) {
        foreach ($extract in ($env:KISS_EXTRACTS -split ':')) {
            if (-not (Test-Path -LiteralPath $extract)) { continue }
            $match = Get-Content -LiteralPath $extract |
                Where-Object { $_ -match "^$([regex]::Escape($Key))=" } |
                Select-Object -First 1
            if ($match) { return ($match -replace "^$([regex]::Escape($Key))=", '') }
        }
    }

    return $Default
}

function Import-KissStandardArgs {
    # Parses -Auto, -Answers FILE, -DryRun, -Help from $args.
    # Returns the remaining positional args so the caller can treat
    # them as its own inputs:
    #   $rest = Import-KissStandardArgs $args
    param([Parameter(ValueFromRemainingArguments=$true)][string[]]$ArgList)

    $rest = @()
    $i = 0
    while ($i -lt $ArgList.Count) {
        switch -Regex ($ArgList[$i]) {
            '^-Auto$'    { $env:KISS_AUTO = '1' }
            '^-DryRun$'  { $env:KISS_DRY_RUN = '1' }
            '^-Answers$' {
                if ($i + 1 -ge $ArgList.Count) { throw '-Answers requires a file path' }
                $env:KISS_ANSWERS = $ArgList[$i + 1]
                $i++
            }
            '^-Help$|^-h$|^--help$' { $rest += '-Help' }
            default      { $rest += $ArgList[$i] }
        }
        $i++
    }
    if ($env:KISS_ANSWERS) { Import-KissAnswers -Path $env:KISS_ANSWERS }
    return $rest
}
