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
Usage: draft-dm-plan.ps1 [-Auto] [-Answers FILE] [-DryRun] [-Help]

Drafts the data migration plan, field mapping, and cutover runbook.

Answer keys: DM_STRATEGY, DM_SOURCE, DM_RECORD_VOLUME,
             DM_CUTOVER_WINDOW, DM_ROLLBACK_TRIGGER, DM_HAS_PII.
Valid strategies: big-bang | phased | parallel | trickle
'@ | Write-Host; exit 0
}

$ctx      = Read-Context
$SkillDir = (Resolve-Path -LiteralPath (Join-Path $ScriptDir '../..')).Path
$Date     = Get-Date -Format 'yyyy-MM-dd'

$Strategy        = Resolve-Auto -Key 'DM_STRATEGY'         -Default 'big-bang'
$Source          = Resolve-Auto -Key 'DM_SOURCE'            -Default 'Legacy system'
$Volume          = Resolve-Auto -Key 'DM_RECORD_VOLUME'     -Default 'Unknown'
$Cutover         = Resolve-Auto -Key 'DM_CUTOVER_WINDOW'    -Default 'TBD'
$RollbackTrigger = Resolve-Auto -Key 'DM_ROLLBACK_TRIGGER'  -Default 'any-failure'
$HasPii          = Resolve-Auto -Key 'DM_HAS_PII'           -Default 'false'

$validStrategies = @('big-bang','phased','parallel','trickle')
if ($Strategy -notin $validStrategies) {
    Write-Warning "Unknown DM_STRATEGY '$Strategy'. Defaulting to 'big-bang'."
    $Strategy = 'big-bang'
    Write-Decision -Kind 'default-applied' -What "DM_STRATEGY set to 'big-bang'" -Why 'invalid value provided' | Out-Null
}

$OpsDir    = Get-WorktypeDir -Name 'operations'
$Out       = Join-Path $OpsDir 'data-migration-plan.md'
$FieldMap  = Join-Path $OpsDir 'field-mapping.md'
$Runbook   = Join-Path $OpsDir 'migration-runbook.md'
$Debts     = Join-Path $OpsDir 'dm-debts.md'

if ($env:KISS_DRY_RUN -eq '1') {
    Write-Host ("[dry-run] would write: {0}" -f $OpsDir)
    Write-Host ("  strategy={0}  source={1}  volume={2}  pii={3}" -f $Strategy, $Source, $Volume, $HasPii)
    exit 0
}

if (-not (Confirm-BeforeWrite -Message "Write data migration plan to $OpsDir/.")) {
    Write-Error 'Aborted.'; exit 1
}

$Project = Split-Path $ctx.REPO_ROOT -Leaf

$rationale = switch ($Strategy) {
    'big-bang'  { 'All data moved in a single cutover window. Simpler coordination but requires planned downtime.' }
    'phased'    { 'Data migrated in batches by domain or date range, allowing partial go-live and risk reduction.' }
    'parallel'  { 'Old and new systems run simultaneously with data kept in sync, enabling near-zero downtime cutover.' }
    'trickle'   { 'Continuous replication via Change Data Capture until the final cutover, minimising downtime for very large datasets.' }
}

$rollbackText = switch ($RollbackTrigger) {
    'any-failure' { 'Any reconciliation check fails (zero-tolerance)' }
    'threshold'   { 'Error rate exceeds 0.1% of total records' }
    'manual'      { 'Manual decision by PM and Tech Lead at Go/No-Go checkpoint' }
    default       { $RollbackTrigger }
}

$privacyNote = if ($HasPii -eq 'true') {
    @"
- All PII fields must be encrypted in transit (TLS 1.2+) and at rest (AES-256).
- Access to migration tooling is restricted to named team members only.
- Audit log of all data access during migration is mandatory.
- GDPR / applicable data protection obligations apply to the migrated data.
"@
} else {
    'No PII identified in migration scope. If this assessment changes, update this section and raise a DMDEBT entry for compliance review.'
}

$tpl = Get-Content -LiteralPath (Join-Path $SkillDir 'templates\dm-plan-template.md') -Raw
$tpl = $tpl.Replace('{project}', $Project).Replace('{revision}', '1.0').Replace('{date}', $Date)
$tpl = $tpl.Replace('{strategy}', $Strategy).Replace('{cutover_window}', $Cutover)
$tpl = $tpl.Replace('{source_system}', $Source).Replace('{target_system}', "$Project (new)")
$tpl = $tpl.Replace('{record_volume}', $Volume).Replace('{has_pii}', $HasPii)
$tpl = $tpl.Replace('{duration_estimate}', 'TBD (based on volume and strategy)')
$tpl = $tpl.Replace('{strategy_rationale}', $rationale)
$tpl = $tpl.Replace('{rollback_trigger}', $rollbackText)
$tpl = $tpl.Replace('{null_action}', 'Set to field default or log DMDEBT')
$tpl = $tpl.Replace('{dedup_key}', 'primary business key')
$tpl = $tpl.Replace('{extract_mechanism}', 'TBD — specify DB export method or API')
$tpl = $tpl.Replace('{extract_mode}', 'full')
$tpl = $tpl.Replace('{batch_size}', '10,000')
$tpl = $tpl.Replace('{transform_rules}', '<!-- AI: populate from field-mapping.md -->')
$tpl = $tpl.Replace('{idempotency_key}', 'business_id')
$tpl = $tpl.Replace('{in_scope}', '<!-- AI: populate from SRS and design documents -->')
$tpl = $tpl.Replace('{out_scope}', '<!-- AI: populate from SRS out-of-scope -->')
$tpl = $tpl.Replace('{privacy_notes}', $privacyNote)
Set-Content -LiteralPath $Out -Value $tpl

$fmTpl = Get-Content -LiteralPath (Join-Path $SkillDir 'templates\field-mapping-template.md') -Raw
$fmTpl = $fmTpl.Replace('{project}', $Project).Replace('{date}', $Date).Replace('{strategy}', $Strategy)
$fmTpl = $fmTpl.Replace('{mapping_sections}', '<!-- AI: populate one section per target entity from design data model -->')
$fmTpl = $fmTpl.Replace('{unmapped_rows}', '<!-- AI: list fields with no source mapping -->')
Set-Content -LiteralPath $FieldMap -Value $fmTpl

Set-Content -LiteralPath $Runbook -Value @"
# Migration Cutover Runbook: $Project

**Strategy:** $Strategy
**Cutover window:** $Cutover
**Rollback trigger:** $rollbackText

## Pre-cutover checklist (T-1 day)

- [ ] Dry-run results reviewed and approved
- [ ] All DMDEBT blockers resolved
- [ ] Stakeholders notified of maintenance window
- [ ] Rollback environment (source DB snapshot) confirmed

## Cutover steps

<!-- AI: expand steps from dm-plan-template.md cutover plan -->

## Post-cutover validation

See Section 7 of data-migration-plan.md.
"@

Write-Extract -ArtefactPath $Out `
    "DM_STRATEGY=$Strategy" `
    "DM_SOURCE=$Source" `
    "DM_RECORD_VOLUME=$Volume" `
    "DM_CUTOVER_WINDOW=$Cutover" `
    "DM_ROLLBACK_TRIGGER=$RollbackTrigger" `
    "DM_HAS_PII=$HasPii" `
    "DM_PLAN_DATE=$Date" | Out-Null

Write-Host ("Wrote {0}" -f $Out)
Write-Host ("Wrote {0}" -f $FieldMap)
Write-Host ("Wrote {0}" -f $Runbook)
